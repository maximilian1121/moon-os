#include "bluetoothmanager.h"
#include <QProcess>
#include <QDebug>

BluetoothManager::BluetoothManager(QObject *parent) : QObject(parent)
{
    m_discoveryTimer = new QTimer(this);
    m_discoveryTimer->setSingleShot(true);
    m_discoveryTimer->setInterval(20000);
    connect(m_discoveryTimer, &QTimer::timeout, this, [this]() {
        if (m_discovering) stopDiscovery();
    });
}

QVariantList BluetoothManager::devices() const
{
    QVariantList list;
    for (const auto &d : m_devices) {
        QVariantMap m;
        m["address"] = d.address;
        m["name"] = d.name.isEmpty() ? d.address : d.name;
        m["paired"] = d.paired;
        m["connected"] = d.connected;
        m["isGamepad"] = d.isGamepad;
        list.append(m);
    }
    return list;
}

bool BluetoothManager::hasConnectedGamepad() const
{
    return m_hasConnectedGamepad;
}

void BluetoothManager::startDiscovery()
{
    if (m_discovering) return;
    QProcess *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p](int) {
        p->deleteLater();
    });
    p->start("bluetoothctl", {"--", "scan", "on"});
    m_discovering = true;
    m_discoveryTimer->start();
    emit scanningChanged();

    m_pollTimer = new QTimer(this);
    m_pollTimer->setInterval(2000);
    connect(m_pollTimer, &QTimer::timeout, this, &BluetoothManager::pollDevices);
    m_pollTimer->start();
}

void BluetoothManager::stopDiscovery()
{
    if (!m_discovering) return;
    QProcess *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [p](int) { p->deleteLater(); });
    p->start("bluetoothctl", {"--", "scan", "off"});
    m_discovering = false;
    m_discoveryTimer->stop();
    if (m_pollTimer) m_pollTimer->stop();
    emit scanningChanged();
}

void BluetoothManager::pairDevice(const QString &address)
{
    QProcess *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, address, p](int) {
        QString out = p->readAllStandardOutput();
        p->deleteLater();
        if (out.contains("successful")) {
            for (auto &d : m_devices) {
                if (d.address == address) d.paired = true;
            }
            emit devicesChanged();
            connectDevice(address);
        }
    });
    p->start("bluetoothctl", {"--", "pair", address});
}

void BluetoothManager::connectDevice(const QString &address)
{
    QProcess *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, address, p](int) {
        p->deleteLater();
        for (auto &d : m_devices) {
            if (d.address == address) {
                d.connected = true;
                emit deviceConnected(d.name);
            }
        }
        emit devicesChanged();
        checkAllGamepadsConnected();
    });
    p->start("bluetoothctl", {"--", "connect", address});
}

void BluetoothManager::scanAndConnectGamepads()
{
    m_devices.clear();
    emit devicesChanged();
    startDiscovery();
}

void BluetoothManager::pollDevices()
{
    QProcess p;
    p.start("bluetoothctl", {"--", "devices"});
    p.waitForFinished(3000);
    QString out = p.readAllStandardOutput();

    QStringList lines = out.split('\n', Qt::SkipEmptyParts);
    bool changed = false;

    for (const QString &line : lines) {
        QStringList parts = line.split(' ', Qt::SkipEmptyParts);
        if (parts.size() < 3) continue;

        QString addr = parts[1];
        QString name = parts.mid(2).join(' ');

        bool exists = false;
        for (const auto &d : m_devices) {
            if (d.address == addr) { exists = true; break; }
        }
        if (exists) continue;

        QProcess info;
        info.start("bluetoothctl", {"--", "info", addr});
        info.waitForFinished(3000);
        QString infoOut = info.readAllStandardOutput();

        bool isGamepad = infoOut.contains("00001124-0000-1000-8000-00805f9b34fb") ||
                         infoOut.contains("Gamepad") ||
                         infoOut.contains("Joystick") ||
                         infoOut.contains("HID");

        BluetoothDevice d;
        d.address = addr;
        d.name = name;
        d.isGamepad = isGamepad;
        d.paired = infoOut.contains("Paired: yes");
        d.connected = infoOut.contains("Connected: yes");
        m_devices.append(d);
        changed = true;

        if (isGamepad && !d.paired) {
            pairDevice(addr);
        } else if (isGamepad && !d.connected) {
            connectDevice(addr);
        }
    }

    if (changed) {
        emit devicesChanged();
    }

    checkAllGamepadsConnected();
}

void BluetoothManager::checkAllGamepadsConnected()
{
    bool allConnected = true;
    bool hasGamepad = false;
    bool anyConnected = false;
    for (const auto &d : m_devices) {
        if (d.isGamepad) {
            hasGamepad = true;
            if (d.connected) anyConnected = true;
            if (!d.connected) allConnected = false;
        }
    }

    if (anyConnected != m_hasConnectedGamepad) {
        m_hasConnectedGamepad = anyConnected;
        emit hasConnectedGamepadChanged();
    }

    if (hasGamepad && allConnected) {
        stopDiscovery();
        emit allGamepadsConnected();
    }
}
