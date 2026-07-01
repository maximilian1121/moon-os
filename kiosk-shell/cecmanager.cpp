#include "cecmanager.h"
#include <QFile>
#include <QDebug>

// ─── Worker ────────────────────────────────────────────────────────────────
CecWorker::CecWorker(QObject *parent) : QObject(parent) {}
CecWorker::~CecWorker() { stop(); }

void CecWorker::start()
{
#ifdef HAS_CEC
    m_config.Clear();
    m_config.clientVersion = LIBCEC_VERSION_CURRENT;
    snprintf(m_config.strDeviceName, sizeof(m_config.strDeviceName), "Moonlight");
    m_config.bActivateSource = 0;
    m_config.deviceTypes.Add(CEC_DEVICE_TYPE_PLAYBACK_DEVICE);

    ICECCallbacks callbacks;
    callbacks.keyPress = [](void *cbParam, const cec_keypress *key) {
        auto *self = static_cast<CecWorker *>(cbParam);
        emit self->buttonPressed(key->keycode);
    };
    m_config.callbacks = callbacks;
    m_config.callbackParam = this;

    m_adapter = LibCEC_Raw->Create(&m_config);
    if (!m_adapter || !m_adapter->Open("/dev/cec0")) {
        emit error("CEC not available");
        return;
    }

    qInfo() << "CEC adapter connected";
#else
    emit error("CEC support not compiled");
#endif
}

void CecWorker::stop()
{
#ifdef HAS_CEC
    if (m_adapter) {
        m_adapter->Close();
        LibCEC_Raw->Destroy(m_adapter);
        m_adapter = nullptr;
    }
#endif
}

// ─── Manager ───────────────────────────────────────────────────────────────
CecManager::CecManager(QObject *parent) : QObject(parent)
{
    // Detect CEC device
#ifdef HAS_CEC
    m_available = QFile::exists("/dev/cec0");
    emit availableChanged();
#endif
}

CecManager::~CecManager()
{
    stop();
}

void CecManager::start()
{
    if (m_thread) return;

    m_thread = new QThread(this);
    m_worker = new CecWorker;
    m_worker->moveToThread(m_thread);

    connect(m_thread, &QThread::started, m_worker, &CecWorker::start);
    connect(m_thread, &QThread::finished, m_worker, &QObject::deleteLater);

#ifdef HAS_CEC
    connect(m_worker, &CecWorker::buttonPressed, this, [this](int key) {
        switch (key) {
        case CEC_USER_CONTROL_CODE_UP:          emit upPressed(); break;
        case CEC_USER_CONTROL_CODE_DOWN:        emit downPressed(); break;
        case CEC_USER_CONTROL_CODE_LEFT:        emit leftPressed(); break;
        case CEC_USER_CONTROL_CODE_RIGHT:       emit rightPressed(); break;
        case CEC_USER_CONTROL_CODE_SELECT:
        case CEC_USER_CONTROL_CODE_ENTER:       emit selectPressed(); break;
        case CEC_USER_CONTROL_CODE_EXIT:
        case CEC_USER_CONTROL_CODE_BACK:        emit backPressed(); break;
        default: break;
        }
    });
#endif

    m_thread->start();
}

void CecManager::stop()
{
    if (m_thread) {
        m_worker->stop();
        m_thread->quit();
        m_thread->wait();
        m_thread = nullptr;
        m_worker = nullptr;
    }
}
