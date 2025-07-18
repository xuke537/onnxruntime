# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

#  include_directories("${CMAKE_CURRENT_BINARY_DIR}/onnx")
  file(GLOB_RECURSE onnxruntime_providers_openvino_cc_srcs CONFIGURE_DEPENDS
    "${ONNXRUNTIME_ROOT}/core/providers/openvino/*.h"
    "${ONNXRUNTIME_ROOT}/core/providers/openvino/*.cc"
    "${ONNXRUNTIME_ROOT}/core/providers/openvino/*.hpp"
    "${ONNXRUNTIME_ROOT}/core/providers/openvino/*.cpp"
    "${ONNXRUNTIME_ROOT}/core/providers/shared_library/*.h"
    "${ONNXRUNTIME_ROOT}/core/providers/shared_library/*.cc"
  )

  # Header paths
  find_package(OpenVINO REQUIRED COMPONENTS Runtime ONNX)
  if(OpenVINO_VERSION VERSION_LESS 2024.5)
    message(FATAL_ERROR "OpenVINO 2024.5 and newer are supported. Please, use latest OpenVINO release")
  endif()

  if(OpenVINO_VERSION VERSION_GREATER_EQUAL 2024.4)
    add_definitions(-DUSE_OVEP_NPU_MEMORY=1)
  endif()

  # If building RelWithDebInfo and OV package does not have that configuration map to Release
  get_target_property(ov_rt_implib_rwdi openvino::runtime IMPORTED_IMPLIB_RELWITHDEBINFO)
  if ((CMAKE_BUILD_TYPE STREQUAL RelWithDebInfo) AND NOT ov_rt_implib_rwdi)
    set_target_properties(openvino::runtime PROPERTIES
      MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
    )
  endif()

  list(APPEND OPENVINO_LIB_LIST openvino::frontend::onnx openvino::runtime ${PYTHON_LIBRARIES})
  source_group(TREE ${ONNXRUNTIME_ROOT}/core FILES ${onnxruntime_providers_openvino_cc_srcs})
  onnxruntime_add_shared_library_module(onnxruntime_providers_openvino ${onnxruntime_providers_openvino_cc_srcs} "${ONNXRUNTIME_ROOT}/core/dll/onnxruntime.rc")

  onnxruntime_add_include_to_target(onnxruntime_providers_openvino onnxruntime_common onnx nlohmann_json::nlohmann_json)
  install(FILES ${PROJECT_SOURCE_DIR}/../include/onnxruntime/core/providers/openvino/openvino_provider_factory.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/onnxruntime/)
  set_target_properties(onnxruntime_providers_openvino PROPERTIES CXX_STANDARD 20)
  set_target_properties(onnxruntime_providers_openvino PROPERTIES LINKER_LANGUAGE CXX)
  set_target_properties(onnxruntime_providers_openvino PROPERTIES FOLDER "ONNXRuntime")

  target_compile_options(onnxruntime_providers_openvino PRIVATE
  $<$<CONFIG:Release>:-DRELEASE>
  )

  if(NOT MSVC)
    target_compile_options(onnxruntime_providers_openvino PRIVATE "-Wno-parentheses")
  endif()
  add_dependencies(onnxruntime_providers_openvino onnxruntime_providers_shared ${onnxruntime_EXTERNAL_DEPENDENCIES})
  target_include_directories(onnxruntime_providers_openvino SYSTEM PUBLIC ${ONNXRUNTIME_ROOT} ${CMAKE_CURRENT_BINARY_DIR} ${OpenVINO_INCLUDE_DIR} ${OPENVINO_INCLUDE_DIR_LIST} ${PYTHON_INCLUDE_DIRS} $ENV{OPENCL_INCS} $ENV{OPENCL_INCS}/../../cl_headers/)
  target_link_libraries(onnxruntime_providers_openvino ${ONNXRUNTIME_PROVIDERS_SHARED} Boost::mp11 ${OPENVINO_LIB_LIST} ${ABSEIL_LIBS} Eigen3::Eigen)

  target_compile_definitions(onnxruntime_providers_openvino PRIVATE FILE_NAME=\"onnxruntime_providers_openvino.dll\")

  if(MSVC)
    target_compile_options(onnxruntime_providers_openvino PRIVATE /wd4099 /wd4275 /wd4100 /wd4005)
  endif()

  # Needed for the provider interface, as it includes training headers when training is enabled
  if (onnxruntime_ENABLE_TRAINING_OPS)
    target_include_directories(onnxruntime_providers_openvino PRIVATE ${ORTTRAINING_ROOT})
  endif()

  if(APPLE)
    set_property(TARGET onnxruntime_providers_openvino APPEND_STRING PROPERTY LINK_FLAGS "-Xlinker -exported_symbols_list ${ONNXRUNTIME_ROOT}/core/providers/openvino/exported_symbols.lst")
  elseif(UNIX)
    set_property(TARGET onnxruntime_providers_openvino APPEND_STRING PROPERTY LINK_FLAGS "-Xlinker --version-script=${ONNXRUNTIME_ROOT}/core/providers/openvino/version_script.lds -Xlinker --gc-sections")
  elseif(WIN32)
    set_property(TARGET onnxruntime_providers_openvino APPEND_STRING PROPERTY LINK_FLAGS "-DEF:${ONNXRUNTIME_ROOT}/core/providers/openvino/symbols.def")
  else()
    message(FATAL_ERROR "onnxruntime_providers_openvino unknown platform, need to specify shared library exports for it")
  endif()

  if (CMAKE_OPENVINO_LIBRARY_INSTALL_DIR)
    install(TARGETS onnxruntime_providers_openvino
            ARCHIVE  DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY  DESTINATION ${CMAKE_OPENVINO_LIBRARY_INSTALL_DIR}
            RUNTIME  DESTINATION ${CMAKE_INSTALL_BINDIR})
  else()
    install(TARGETS onnxruntime_providers_openvino
            ARCHIVE  DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY  DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME  DESTINATION ${CMAKE_INSTALL_BINDIR})
  endif()

set_target_properties(onnxruntime_providers_openvino PROPERTIES
  MAP_IMPORTED_CONFIG_RELEASE RelWithDebInfo
  MAP_IMPORTED_CONFIG_DEBUG RelWithDebInfo
  )
