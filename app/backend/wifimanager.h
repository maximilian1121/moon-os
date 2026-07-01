#pragma once

#include <QObject>
#include <QVariantList>
#include <QProcess>
#include <QTimer>

class WifiManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList networks READ networks NOTIFY networksChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString connectedSsid READ connectedSsid NOTIFY connectedSsidChanged)

public:
    explicit WifiManager(QObject *parent = nullptr);

    QVariantList networks() const { return m_networks; }
    QString status() const { return m_status; }
    QString connectedSsid() const { return m_connectedSsid; }

    Q_INVOKABLE void scan();
    Q_INVOKABLE void connectToNetwork(const QString &ssid, const QString &password = QString());
    Q_INVOKABLE void refreshStatus();

signals:
    void networksChanged();
    void statusChanged();
    void connectedSsidChanged();
    void connected(const QString &ssid);

private:
    void pollActiveConnection();

    QVariantList m_networks;
    QString m_status;
    QString m_connectedSsid;
    QTimer *m_pollTimer;
};
