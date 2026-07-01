#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QFile>
#include <QProcess>

#include <SDL.h>

#include "bluetoothmanager.h"
#include "wifimanager.h"
#include "cecmanager.h"

// ─── Controller Input Bridge ─────────────────────────────────────────────
class ControllerInput : public QObject
{
    Q_OBJECT
public:
    explicit ControllerInput(QObject *parent = nullptr)
        : QObject(parent)
    {
        SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
        if (SDL_Init(SDL_INIT_GAMECONTROLLER | SDL_INIT_EVENTS) < 0)
            qWarning("SDL_Init failed: %s", SDL_GetError());

        m_gc = nullptr;
        for (int i = 0; i < SDL_NumJoysticks(); i++) {
            if (SDL_IsGameController(i)) {
                m_gc = SDL_GameControllerOpen(i);
                if (m_gc) break;
            }
        }

        m_timer = new QTimer(this);
        m_timer->setInterval(16);
        connect(m_timer, &QTimer::timeout, this, &ControllerInput::poll);
        m_timer->start();
    }

    ~ControllerInput()
    {
        m_timer->stop();
        if (m_gc) SDL_GameControllerClose(m_gc);
        SDL_Quit();
    }

signals:
    void navUp();
    void navDown();
    void navLeft();
    void navRight();
    void accept();
    void back();

private:
    void poll()
    {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            switch (e.type) {
            case SDL_CONTROLLERDEVICEADDED:
                if (!m_gc) m_gc = SDL_GameControllerOpen(e.cdevice.which);
                break;
            case SDL_CONTROLLERDEVICEREMOVED:
                if (m_gc && e.cdevice.which == SDL_JoystickInstanceID(
                        SDL_GameControllerGetJoystick(m_gc))) {
                    SDL_GameControllerClose(m_gc);
                    m_gc = nullptr;
                }
                break;
            case SDL_CONTROLLERBUTTONDOWN:
                switch (e.cbutton.button) {
                case SDL_CONTROLLER_BUTTON_DPAD_UP:     emit navUp(); break;
                case SDL_CONTROLLER_BUTTON_DPAD_DOWN:   emit navDown(); break;
                case SDL_CONTROLLER_BUTTON_DPAD_LEFT:   emit navLeft(); break;
                case SDL_CONTROLLER_BUTTON_DPAD_RIGHT:  emit navRight(); break;
                case SDL_CONTROLLER_BUTTON_A:           emit accept(); break;
                case SDL_CONTROLLER_BUTTON_B:           emit back(); break;
                default: break;
                }
                break;
            case SDL_CONTROLLERAXISMOTION: {
                if (e.caxis.axis == SDL_CONTROLLER_AXIS_LEFTX ||
                    e.caxis.axis == SDL_CONTROLLER_AXIS_RIGHTX) {
                    if (abs(e.caxis.value) > 16384) {
                        if (e.caxis.value < 0) emit navLeft();
                        else emit navRight();
                        SDL_Delay(180);
                    }
                } else if (e.caxis.axis == SDL_CONTROLLER_AXIS_LEFTY ||
                           e.caxis.axis == SDL_CONTROLLER_AXIS_RIGHTY) {
                    if (abs(e.caxis.value) > 16384) {
                        if (e.caxis.value < 0) emit navUp();
                        else emit navDown();
                        SDL_Delay(180);
                    }
                }
                break;
            }
            default:
                break;
            }
        }
    }

    SDL_GameController *m_gc = nullptr;
    QTimer *m_timer = nullptr;
};

// ─── Moonlight Launcher ──────────────────────────────────────────────────
// The kiosk exits with a specific exit code to signal the wrapper script:
//   0  → launch Moonlight then restart kiosk
//   1  → exit (no restart)
// Any other → error, restart by systemd

class MoonlightLauncher : public QObject
{
    Q_OBJECT
public:
    explicit MoonlightLauncher(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void launch()
    {
        QGuiApplication::exit(0);
    }

    Q_INVOKABLE void quitKiosk()
    {
        QGuiApplication::exit(1);
    }

    Q_INVOKABLE void writeConfig()
    {
        QFile f("/home/pi/.moonlight-configured");
        f.open(QIODevice::WriteOnly);
        f.write("configured");
        f.close();
    }
};

// ─── Main ─────────────────────────────────────────────────────────────────
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Moonlight Kiosk");
    app.setApplicationVersion("1.0");

    // ── Controller ──
    ControllerInput ctrl;

    // ── CEC ──
    CecManager cecMgr;

    // ── Bluetooth ──
    BluetoothManager btMgr;

    // ── WiFi ──
    WifiManager wifiMgr;

    // ── Moonlight Launcher ──
    MoonlightLauncher launcher;

    // ── QML ──
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("controllerInput", &ctrl);
    engine.rootContext()->setContextProperty("cecManager", &cecMgr);
    engine.rootContext()->setContextProperty("bluetoothManager", &btMgr);
    engine.rootContext()->setContextProperty("wifiManager", &wifiMgr);
    engine.rootContext()->setContextProperty("moonlightLauncher", &launcher);

    bool onboardingDone = QFile::exists("/home/pi/.moonlight-configured");
    engine.rootContext()->setContextProperty("onboardingDone", onboardingDone);

    engine.load(QUrl("qrc:/qml/main.qml"));

    if (engine.rootObjects().isEmpty())
        return 2;

    return app.exec();
}

#include "main.moc"
