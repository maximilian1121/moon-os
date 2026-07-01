#pragma once

#include <QObject>
#include <QVariantList>
#include <QProcess>

class WifiManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList networks READ networks NOTIFY networksChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit WifiManager(QObject *parent = nullptr);

    QVariantList networks() const { return m_networks; }
    QString status() const { return m_status; }

    Q_INVOKABLE void scan();
    Q_INVOKABLE void connect(const QString &ssid, const QString &password = QString());

signals:
    void networksChanged();
    void statusChanged();
    void connected(const QString &ssid);

private:
    QVariantList m_networks;
    QString m_status;
};
