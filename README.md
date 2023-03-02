# dependencies
this is entirely the same as German's original library except for this README, which provides a better sample of how to actually use it in your project to include or install directories from github

####
#### DEPENDENCIES (installing this library into your poject CMake)
####
find_package (Dependencies QUIET)

if (NOT ${Dependencies_FOUND})

    if (NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/DependenciesConfig.cmake)
    
        file(DOWNLOAD https://raw.githubusercontent.com/germanespinosa/dependencies/main/DependenciesConfig.cmake ${CMAKE_CURRENT_BINARY_DIR}/DependenciesConfig.cmake)
        
    endif()
    
    set(Dependencies_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    
    find_package (Dependencies REQUIRED)
    
endif()

####
#### END DEPENDENCIES

####


then if you want to use it to install a library to your project, in this case easy-tcp, you can add the following below

install_git_dependency(easy-tcp https://github.com/germanespinosa/easy-tcp CMAKE_PROJECT #can be used as a passive import, this flag compiles this in cmake
        INCLUDE_DIRECTORIES include #sort of merge a project into my own
        IMPORT_TARGETS easy-tcp) #brings over the target created by the CMake project
       
include_directories(dependencies/easy-tcp/include)
