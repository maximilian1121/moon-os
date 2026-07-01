TEMPLATE = subdirs
SUBDIRS = \
    moonlight-common-c \
    qmdnsengine \
    app \
    h264bitstream

app.depends = qmdnsengine moonlight-common-c h264bitstream

CONFIG += debug_and_release

load(configure)
qtCompileTest(EGL)
