#include "wifimanager.h"
#include <QDebug>
#include <QSet>

WifiManager::WifiManager(QObject *parent) : QObject(parent)
{
    m_pollTimer = new QTimer(this);
    m_pollTimer->setInterval(10000);
    connect(m_pollTimer, &QTimer::timeout, this, &WifiManager::pollActiveConnection);
    m_pollTimer->start();

    refreshStatus();
}

void WifiManager::refreshStatus()
{
    pollActiveConnection();
}

void WifiManager::pollActiveConnection()
{
    QProcess *p = new QProcess(this);
    QObject::connect(p, &QProcess::finished, this, [this, p](int) {
        QString out = QString::fromUtf8(p->readAllStandardOutput());
        p->deleteLater();

        QString ssid;
        for (const QString &line : out.split('\n')) {
            if (line.trimmed().startsWith("*")) {
                int colon = line.lastIndexOf(':');
                if (colon > 0) {
                    ssid = line.mid(colon + 1).trimmed();
                }
            }
        }

        if (ssid != m_connectedSsid) {
            m_connectedSsid = ssid;
            emit connectedSsidChanged();
        }
    });
    p->start("nmcli", {"-t", "-f", "ACTIVE,SSID", "connection", "show", "--active"});
}

void WifiManager::scan()
{
    QProcess *p = new QProcess(this);
    QObject::connect(p, &QProcess::finished, this, [this, p](int) {
        QByteArray data = p->readAllStandardOutput();
        p->deleteLater();

        m_networks.clear();
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

            int signal = bars.count('*') * 25;
            if (signal == 0 && bars.length() > 0)
                signal = qMin(bars.length() * 14, 100);

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

void WifiManager::connectToNetwork(const QString &ssid, const QString &password)
{
    m_status = QString("Connecting to %1...").arg(ssid);
    emit statusChanged();

    QProcess *p = new QProcess(this);
    QObject::connect(p, &QProcess::finished, this, [this, ssid, p](int exitCode) {
        QString err = p->readAllStandardError();
        p->deleteLater();
        if (exitCode == 0) {
            m_status = QString("Connected to %1").arg(ssid);
            m_connectedSsid = ssid;
            emit connected(ssid);
            emit connectedSsidChanged();
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
