#include "wifimanager.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

WifiManager::WifiManager(QObject *parent) : QObject(parent) {}

void WifiManager::scan()
{
    QProcess *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p](int) {
        QByteArray data = p->readAllStandardOutput();
        p->deleteLater();

        m_networks.clear();
        // nmcli -t output: colon-delimited fields
        QStringList lines = QString::fromUtf8(data).split('\n', Qt::SkipEmptyParts);
        QSet<QString> seen;

        for (const QString &line : lines) {
            if (line.trimmed().isEmpty()) continue;
            QStringList cols = line.split(':');
            if (cols.size() < 4) continue;

            QString inUse = cols[0];
            QString ssid  = cols[1];
            QString bars  = cols[2];
            QString sec   = cols[3];

            if (ssid.isEmpty() || ssid == "--" || seen.contains(ssid)) continue;
            seen.insert(ssid);

            int signal = bars.count(QLatin1Char('█')) * 25;
            if (signal == 0 && !bars.isEmpty()) signal = bars.count('*') * 25;
            if (signal == 0) signal = bars.count('.');  // empty boxes

            QVariantMap net;
            net["ssid"] = ssid;
            net["signal"] = qMin(signal, 100);
            net["security"] = sec;
            net["active"] = inUse == "*";
            m_networks.append(net);
        }

        emit networksChanged();
    });

    p->start("nmcli", {"-t", "-f", "IN-USE,SSID,BARS,SECURITY", "device", "wifi", "list", "--rescan", "yes"});
}

void WifiManager::connect(const QString &ssid, const QString &password)
{
    m_status = QString("Connecting to %1...").arg(ssid);
    emit statusChanged();

    QProcess *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, ssid, p](int exitCode) {
        QString err = p->readAllStandardError();
        p->deleteLater();
        if (exitCode == 0) {
            m_status = QString("Connected to %1").arg(ssid);
            emit connected(ssid);
        } else {
            m_status = QString("Failed: %1").arg(err.trimmed());
        }
        emit statusChanged();
    });

    QStringList args = {"device", "wifi", "connect", ssid};
    if (!password.isEmpty()) {
        args << "password" << password;
    }
    p->start("nmcli", args);
}
