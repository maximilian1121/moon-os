#pragma once

#include <QObject>
#include <QVariantList>
#include <QTimer>
#include <QList>

struct BluetoothDevice {
    QString address;
    QString name;
    bool paired = false;
    bool connected = false;
    bool isGamepad = false;
};

class BluetoothManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)

public:
    explicit BluetoothManager(QObject *parent = nullptr);

    bool scanning() const { return m_discovering; }
    QVariantList devices() const;

    Q_INVOKABLE void startDiscovery();
    Q_INVOKABLE void stopDiscovery();
    Q_INVOKABLE void pairDevice(const QString &address);
    Q_INVOKABLE void connectDevice(const QString &address);
    Q_INVOKABLE void scanAndConnectGamepads();

signals:
    void scanningChanged();
    void devicesChanged();
    void deviceConnected(const QString &name);
    void allGamepadsConnected();

private:
    void pollDevices();
    void checkAllGamepadsConnected();

    QList<BluetoothDevice> m_devices;
    bool m_discovering = false;
    QTimer *m_discoveryTimer = nullptr;
    QTimer *m_pollTimer = nullptr;
};
