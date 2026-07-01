QT += core quick network quickcontrols2 svg
CONFIG += c++17

TARGET = moonlight

include(../globaldefs.pri)

TEMPLATE = app

DEFINES += QT_DEPRECATED_WARNINGS
DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000

CONFIG += link_pkgconfig
PKGCONFIG += openssl sdl2 SDL2_ttf opus

packagesExist(libcec) {
    PKGCONFIG += libcec
    DEFINES += HAS_CEC
}

!disable-ffmpeg {
    packagesExist(libavcodec) {
        PKGCONFIG += libavcodec libavutil libswscale
        CONFIG += ffmpeg

        !disable-mmal {
            packagesExist(mmal) {
                PKGCONFIG += mmal
                CONFIG += mmal
            }
        }

        !disable-libdrm {
            packagesExist(libdrm) {
                PKGCONFIG += libdrm
                CONFIG += libdrm
            }
        }
    }

    !disable-wayland {
        packagesExist(wayland-client) {
            CONFIG += wayland
            PKGCONFIG += wayland-client
        }
    }

    !disable-x11 {
        packagesExist(x11) {
            DEFINES += HAS_X11
            PKGCONFIG += x11
        }
    }
}

SOURCES += \
    backend/nvaddress.cpp \
    backend/nvapp.cpp \
    cli/pair.cpp \
    main.cpp \
    backend/computerseeker.cpp \
    backend/identitymanager.cpp \
    backend/nvcomputer.cpp \
    backend/nvhttp.cpp \
    backend/nvpairingmanager.cpp \
    backend/computermanager.cpp \
    backend/boxartmanager.cpp \
    backend/richpresencemanager.cpp \
    cli/commandlineparser.cpp \
    cli/listapps.cpp \
    cli/quitstream.cpp \
    cli/startstream.cpp \
    settings/compatfetcher.cpp \
    settings/mappingfetcher.cpp \
    settings/streamingpreferences.cpp \
    streaming/input/abstouch.cpp \
    streaming/input/gamepad.cpp \
    streaming/input/input.cpp \
    streaming/input/keyboard.cpp \
    streaming/input/mouse.cpp \
    streaming/input/reltouch.cpp \
    streaming/session.cpp \
    streaming/audio/audio.cpp \
    streaming/audio/renderers/sdlaud.cpp \
    gui/computermodel.cpp \
    gui/appmodel.cpp \
    streaming/bandwidth.cpp \
    streaming/streamutils.cpp \
    backend/autoupdatechecker.cpp \
    backend/wifimanager.cpp \
    backend/bluetoothmanager.cpp \
    backend/cecmanager.cpp \
    path.cpp \
    settings/mappingmanager.cpp \
    gui/sdlgamepadkeynavigation.cpp \
    streaming/video/overlaymanager.cpp \
    backend/systemproperties.cpp \
    wm.cpp

HEADERS += \
    SDL_compat.h \
    backend/nvaddress.h \
    backend/nvapp.h \
    cli/pair.h \
    settings/compatfetcher.h \
    settings/mappingfetcher.h \
    utils.h \
    backend/computerseeker.h \
    backend/identitymanager.h \
    backend/nvcomputer.h \
    backend/nvhttp.h \
    backend/nvpairingmanager.h \
    backend/computermanager.h \
    backend/boxartmanager.h \
    backend/richpresencemanager.h \
    cli/commandlineparser.h \
    cli/listapps.h \
    cli/quitstream.h \
    cli/startstream.h \
    settings/streamingpreferences.h \
    streaming/input/input.h \
    streaming/session.h \
    streaming/audio/renderers/renderer.h \
    streaming/audio/renderers/sdl.h \
    gui/computermodel.h \
    gui/appmodel.h \
    streaming/video/decoder.h \
    streaming/bandwidth.h \
    streaming/streamutils.h \
    backend/autoupdatechecker.h \
    backend/wifimanager.h \
    backend/bluetoothmanager.h \
    backend/cecmanager.h \
    path.h \
    settings/mappingmanager.h \
    gui/sdlgamepadkeynavigation.h \
    streaming/video/overlaymanager.h \
    backend/systemproperties.h

ffmpeg {
    message(FFmpeg decoder selected)

    DEFINES += HAVE_FFMPEG
    SOURCES += \
        streaming/video/ffmpeg.cpp \
        streaming/video/ffmpeg-renderers/genhwaccel.cpp \
        streaming/video/ffmpeg-renderers/sdlvid.cpp \
        streaming/video/ffmpeg-renderers/swframemapper.cpp \
        streaming/video/ffmpeg-renderers/pacer/pacer.cpp

    HEADERS += \
        streaming/video/ffmpeg.h \
        streaming/video/ffmpeg-renderers/renderer.h \
        streaming/video/ffmpeg-renderers/genhwaccel.h \
        streaming/video/ffmpeg-renderers/sdlvid.h \
        streaming/video/ffmpeg-renderers/swframemapper.h \
        streaming/video/ffmpeg-renderers/pacer/pacer.h
}

mmal {
    message(MMAL renderer selected)

    DEFINES += HAVE_MMAL
    SOURCES += streaming/video/ffmpeg-renderers/mmal.cpp
    HEADERS += streaming/video/ffmpeg-renderers/mmal.h

    allow-egl-with-mmal {
        message(Allowing EGL usage with MMAL enabled)
        DEFINES += ALLOW_EGL_WITH_MMAL
    }
}

libdrm {
    message(DRM renderer selected)

    DEFINES += HAVE_DRM
    SOURCES += streaming/video/ffmpeg-renderers/drm.cpp
    HEADERS += streaming/video/ffmpeg-renderers/drm.h

    !disable-masterhooks {
        message(Master hooks enabled)
        DEFINES += HAVE_DRM_MASTER_HOOKS
        SOURCES += masterhook.c masterhook_internal.c
        LIBS += -ldl -pthread
    }
}

config_EGL {
    message(EGL renderer selected)

    CONFIG += egl
    DEFINES += HAVE_EGL
    SOURCES += \
        streaming/video/ffmpeg-renderers/eglvid.cpp \
        streaming/video/ffmpeg-renderers/egl_extensions.cpp \
        streaming/video/ffmpeg-renderers/eglimagefactory.cpp
    HEADERS += \
        streaming/video/ffmpeg-renderers/eglvid.h \
        streaming/video/ffmpeg-renderers/eglimagefactory.h
}

embedded {
    message(Embedded build)
    DEFINES += EMBEDDED_BUILD
}

gpuslow {
    message(GPU slow build)
    DEFINES += GL_IS_SLOW VULKAN_IS_SLOW
}

wayland {
    message(Wayland extensions enabled)
    DEFINES += HAS_WAYLAND
    SOURCES += streaming/video/ffmpeg-renderers/pacer/waylandvsyncsource.cpp
    HEADERS += streaming/video/ffmpeg-renderers/pacer/waylandvsyncsource.h
}

RESOURCES += \
    resources.qrc \
    qml.qrc

TRANSLATIONS += \
    languages/qml_zh_CN.ts \
    languages/qml_de.ts \
    languages/qml_fr.ts \
    languages/qml_nb_NO.ts \
    languages/qml_ru.ts \
    languages/qml_es.ts \
    languages/qml_ja.ts \
    languages/qml_vi.ts \
    languages/qml_th.ts \
    languages/qml_ko.ts \
    languages/qml_hu.ts \
    languages/qml_nl.ts \
    languages/qml_sv.ts \
    languages/qml_tr.ts \
    languages/qml_uk.ts \
    languages/qml_zh_TW.ts \
    languages/qml_el.ts \
    languages/qml_hi.ts \
    languages/qml_it.ts \
    languages/qml_pt.ts \
    languages/qml_pt_BR.ts \
    languages/qml_pl.ts \
    languages/qml_cs.ts \
    languages/qml_he.ts \
    languages/qml_ckb.ts \
    languages/qml_lt.ts \
    languages/qml_et.ts \
    languages/qml_bg.ts \
    languages/qml_eo.ts \
    languages/qml_ta.ts

QML_IMPORT_PATH =
QML_DESIGNER_IMPORT_PATH =

LIBS += -L$$OUT_PWD/../moonlight-common-c/ -lmoonlight-common-c
INCLUDEPATH += $$PWD/../moonlight-common-c/moonlight-common-c/src
DEPENDPATH += $$PWD/../moonlight-common-c/moonlight-common-c/src

LIBS += -L$$OUT_PWD/../qmdnsengine/ -lqmdnsengine
INCLUDEPATH += $$PWD/../qmdnsengine/qmdnsengine/src/include $$PWD/../qmdnsengine
DEPENDPATH += $$PWD/../qmdnsengine/qmdnsengine/src/include $$PWD/../qmdnsengine

LIBS += -L$$OUT_PWD/../h264bitstream/ -lh264bitstream
INCLUDEPATH += $$PWD/../h264bitstream/h264bitstream
DEPENDPATH += $$PWD/../h264bitstream/h264bitstream

isEmpty(PREFIX) {
    PREFIX = /usr/local
}
isEmpty(BINDIR) {
    BINDIR = bin
}
isEmpty(DATADIR) {
    DATADIR = share
}

target.path = $$PREFIX/$$BINDIR/

rpi_service.files = $$PWD/deploy/linux/rpi/moonlight-rpi.service
rpi_service.path = $$PREFIX/lib/systemd/system/

rpi_autostart.files = $$PWD/deploy/linux/rpi/autostart/moonlight.desktop
rpi_autostart.path = $$PREFIX/etc/xdg/autostart/

INSTALLS += target rpi_service rpi_autostart

VERSION = "$$cat(version.txt)"
DEFINES += VERSION_STR=\\\"$$cat(version.txt)\\\"
