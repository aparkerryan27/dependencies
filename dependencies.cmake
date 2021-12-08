make_directory (${CMAKE_CURRENT_BINARY_DIR}/dependency_include)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/dependency_include)
file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/dependencies_outputs.txt)
file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/dependencies_packages.txt)


function (dependency_include)
    foreach(include_folder ${ARGN})
        execute_process(COMMAND bash -c "cp ${include_folder}/* ${CMAKE_CURRENT_BINARY_DIR}/dependency_include/ -r"
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}  )
    endforeach()
endfunction()

function (add_dependency_package package_name)
    message(STATUS "Adding package ${package_name} to dependency tree")

    set (variadic_args ${ARGN})
    list(LENGTH variadic_args variadic_count)
    if (${variadic_count} GREATER 0)
        list(GET variadic_args 0 package_DIR)
        set (${package_name}_DIR ${package_DIR})
    endif ()

    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/dependencies_packages.txt "${package_name}/${package_DIR};")

    find_package (${package_name} REQUIRED)
endfunction()

function (add_dependency_output_directory dependency_output_directory)
    message(STATUS "Adding folder ${dependency_output_directory} to dependency tree")
    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/dependencies_outputs.txt "${dependency_output_directory};")
    link_directories(${dependency_output_directory})
endfunction()

function(install_dependency git_repo)

    execute_process(COMMAND basename ${git_repo}
            OUTPUT_VARIABLE repo_name )

    string(REPLACE "\n" "" repo_name ${repo_name})

    message(STATUS "\nConfiguring dependency ${repo_name}")

    set(dependencies_folder "${CMAKE_CURRENT_SOURCE_DIR}/dependencies")

    execute_process(COMMAND mkdir ${dependencies_folder} -p)

    set(dependency_folder "${dependencies_folder}/${repo_name}")

    execute_process(COMMAND bash -c "[ -d ${repo_name} ]"
            WORKING_DIRECTORY ${dependencies_folder}
            RESULT_VARIABLE  folder_exists)

    if (${folder_exists} EQUAL 0)
        execute_process(COMMAND git pull
                WORKING_DIRECTORY ${dependency_folder})
    else()
        execute_process(COMMAND git -C ${dependencies_folder} clone ${git_repo})
    endif()

    set(destination_folder ${CMAKE_CURRENT_BINARY_DIR}/${repo_name})

    execute_process(COMMAND mkdir ${repo_name} -p
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} )

    execute_process(COMMAND bash -c "CATCH_TESTS=NO_TESTS cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} '-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}' -G 'CodeBlocks - Unix Makefiles' ${dependency_folder}"
            WORKING_DIRECTORY ${destination_folder})

    execute_process(COMMAND bash -c "[ -d dependency_include ]"
            WORKING_DIRECTORY ${destination_folder}
            RESULT_VARIABLE  include_folder_exists)

    if (${include_folder_exists} EQUAL 0)
        dependency_include(${destination_folder}|dependency_include)
    endif()

    execute_process(COMMAND bash -c "[ -f dependencies_outputs.txt ]"
            WORKING_DIRECTORY ${destination_folder}
            RESULT_VARIABLE  dependencies_outputs_exists)

    if (${dependencies_outputs_exists} EQUAL 0)
        message(STATUS "dependency_outputs found!")
        file(READ ${destination_folder}/dependencies_outputs.txt dependencies_outputs)
        foreach(output_folder ${dependencies_outputs})
            if (NOT ${output_folder} EQUAL "")
                add_dependency_output_directory(${output_folder})
            endif()
        endforeach()
    endif()

    execute_process(COMMAND bash -c "[ -f dependencies_packages.txt ]"
            WORKING_DIRECTORY ${destination_folder}
            RESULT_VARIABLE  dependencies_packages_exists)

    if (${dependencies_packages_exists} EQUAL 0)
        message(STATUS "dependencies_packages found!")
        file(READ ${destination_folder}/dependencies_packages.txt dependencies_packages)
        foreach(dependencies_package_DIR ${dependencies_packages})
            if (NOT ${dependencies_package_DIR} EQUAL "")
                string(REPLACE "|" ";" dependencies_package_DIR ${dependencies_package_DIR})
                list(GET dependencies_package_DIR 0 dependencies_package_name)
                list(GET dependencies_package_DIR 1 dependencies_package_DIR)
                add_dependency_package(${dependencies_package} ${dependencies_package_DIR})
            endif()
        endforeach()
    endif()

    execute_process(COMMAND make -j
            WORKING_DIRECTORY ${destination_folder})

    set (repo_targets "${destination_folder}/${repo_name}Targets.cmake")

    set (variadic_args ${ARGN})
    list(LENGTH variadic_args variadic_count)
    if (${variadic_count} GREATER 0)
        list(GET variadic_args 0 package_name)
        add_dependency_package (${package_name}  ${destination_folder})
    endif ()
    
    
    add_dependency_output_directory(${destination_folder})
   
endfunction()
