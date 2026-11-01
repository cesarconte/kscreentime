find_package(Qt6Test ${QT_MIN_VERSION} REQUIRED)

add_executable(test_kscreentime
    test_kscreentime.cpp
    ${CMAKE_SOURCE_DIR}/src/resources.qrc
)

target_compile_definitions(test_kscreentime PRIVATE KSCREENTIME_SOURCE_DIR="${CMAKE_SOURCE_DIR}")

target_link_libraries(test_kscreentime PRIVATE
    kscreentime_core
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::DBus
    Qt6::Test
    KF6::Kirigami
)

add_test(NAME test_kscreentime COMMAND test_kscreentime)
