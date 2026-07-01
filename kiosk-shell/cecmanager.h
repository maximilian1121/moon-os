#pragma once

#include <QObject>
#include <QThread>

#ifdef HAS_CEC
#include <libcec/cec.h>
using namespace CEC;
#endif

class CecWorker : public QObject
{
    Q_OBJECT
public:
    explicit CecWorker(QObject *parent = nullptr);
    ~CecWorker();

public slots:
    void start();
    void stop();

signals:
    void buttonPressed(int key);
    void error(const QString &msg);

private:
#ifdef HAS_CEC
    ICECAdapter *m_adapter = nullptr;
    libcec_configuration m_config;
#endif
};

class CecManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)

public:
    explicit CecManager(QObject *parent = nullptr);
    ~CecManager();

    bool available() const { return m_available; }

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

signals:
    void availableChanged();
    void upPressed();
    void downPressed();
    void leftPressed();
    void rightPressed();
    void selectPressed();
    void backPressed();

private:
    QThread *m_thread = nullptr;
    CecWorker *m_worker = nullptr;
    bool m_available = false;
};
