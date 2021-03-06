if(SWIFT_SOURCEKIT_USE_INPROC_LIBRARY)
  set(SOURCEKITD_TEST_DEPEND sourcekitdInProc)
else()
  set(SOURCEKITD_TEST_DEPEND sourcekitd)
endif()

add_sourcekit_executable(complete-test
  complete-test.cpp
  DEPENDS ${SOURCEKITD_TEST_DEPEND}
  COMPONENT_DEPENDS support option
)

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set_target_properties(complete-test
    PROPERTIES
    LINK_FLAGS "-Wl,-rpath -Wl,@executable_path/../lib")

  if(SWIFT_ANALYZE_CODE_COVERAGE)
    set_property(TARGET complete-test APPEND_STRING PROPERTY
      LINK_FLAGS " -fprofile-instr-generate -fcoverage-mapping")
  endif()
endif()

swift_install_in_component(tools
    TARGETS complete-test
    RUNTIME DESTINATION bin)
