add_library(kscreentime_core STATIC
    screentimetracker.cpp
    screentimetracker.h
)

target_include_directories(kscreentime_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(kscreentime_core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::DBus
    KF6::CoreAddons
    KF6::I18n
)

add_executable(kscreentime
    main.cpp
    resources.qrc
)

target_link_libraries(kscreentime PRIVATE
    kscreentime_core
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    KF6::CoreAddons
    KF6::I18n
    KF6::Kirigami
)

install(TARGETS kscreentime DESTINATION ${KDE_INSTALL_BINDIR})
install(FILES org.cesar.kscreentime.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES kscreentime.service DESTINATION ${KDE_INSTALL_DATADIR}/systemd/user)
