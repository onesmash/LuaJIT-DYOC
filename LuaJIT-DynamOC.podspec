Pod::Spec.new do |s|
	s.name				= "LuaJIT-DynamOC"
	s.version			= "1.0.0"
	s.summary			= "LuaJIT for DynamOC"
	s.homepage			= "https://github.com/onesmash/LuaJIT-DYOC"
	s.license      		= { :type => "MIT", :file => "COPYRIGHT" }
	s.author			= { "xuhui" => "good122000@qq.com" }
	s.source			= { :http => "https://raw.githubusercontent.com/onesmash/LuaJIT-DYOC/master/LuaJIT-2.1.0-beta3.zip" }
	s.source_files		= "include/*.h"
	s.ios.deployment_target		= "8.0"
	s.ios.public_header_files	= "include/*.h"
	s.ios.vendored_libraries	= "lib/libluajit.a"
	s.libraries = 'c++'
	s.requires_arc				= false
	s.prepare_command = <<-CMD
		ICC=$(xcrun --find clang)
		SDK_VERSION=$(xcrun --sdk iphoneos --show-sdk-version 2> /dev/null)
		ARCHS="i386 x86_64 armv7 armv7s arm64"
    	DEVELOPER=$(xcode-select -print-path)
    	MIN_SDK_VERSION_FLAG="-miphoneos-version-min=8.0"

		BASE_PATH="${PWD}"
		CURRENT_PATH="/tmp/luajit"
		
		mkdir -p ${CURRENT_PATH}/include

    	cp file.tgz ${CURRENT_PATH}/file.tgz
    	cd ${CURRENT_PATH}
    	unzip file.tgz
    	cd LuaJIT-2.1.0-beta3

    	echo "base path ${BASE_PATH}"

    	sed -i .bak "s/BUILDMODE= mixed/BUILDMODE= static/g" ./src/Makefile

    	cp -v ./src/lua.h ${CURRENT_PATH}/include
		cp -v ./src/lauxlib.h ${CURRENT_PATH}/include
		cp -v ./src/lualib.h ${CURRENT_PATH}/include
		cp -v ./src/luajit.h ${CURRENT_PATH}/include
		cp -v ./src/lua.hpp ${CURRENT_PATH}/include
		cp -v ./src/luaconf.h ${CURRENT_PATH}/include
		cp -v ./src/dynamoc.h ${CURRENT_PATH}/include

		echo "Build library..."
		rm -rf "${BASE_PATH}/lib/"
		mkdir -p "${BASE_PATH}/lib/"
		mkdir -p "${BASE_PATH}/lib/jit"
		cp -vRL "./src/jit/" "${BASE_PATH}/lib/jit/"

		for TARGET_ARCH in ${ARCHS}
		do
			MARCH="-m32"
			HOST_ARCH="i386"
			COMPILE_FLAGS="-DLUAJIT_ENABLE_LUA52COMPAT -DLJ_NO_SYSTEM"
			if [ "${TARGET_ARCH}" == "i386" ] || [ "${TARGET_ARCH}" == "x86_64" ]
	      	then
	        	PLATFORM="iPhoneSimulator"
	        	MIN_SDK_VERSION_FLAG="-mios-simulator-version-min=8.0"
	        	COMPILE_FLAGS="$COMPILE_FLAGS -fembed-bitcode-marker"
	        	if [ "${TARGET_ARCH}" == "x86_64" ]
	        	then
	        		MARCH="-m64"
	        		HOST_ARCH="x86_64"
	        		COMPILE_FLAGS="$COMPILE_FLAGS"
	        	fi
	      	else
	        	PLATFORM="iPhoneOS"
	        	COMPILE_FLAGS="$COMPILE_FLAGS -fembed-bitcode"
	        	if [ "${TARGET_ARCH}" == "arm64" ]
	        	then
	        		MARCH=""
	        		HOST_ARCH="arm64"
	        		COMPILE_FLAGS="$COMPILE_FLAGS"
	        	fi
	      	fi
	      	ISDKP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK_VERSION}.sdk"
	      	ISDKF="-arch ${TARGET_ARCH} -isysroot $ISDKP $MIN_SDK_VERSION_FLAG $COMPILE_FLAGS"
	      	make clean 2> /dev/null 
	      	echo =================================================
	      	echo "build ${TARGET_ARCH} Architecture"
	      	if [ "${TARGET_ARCH}" == "arm64" ] || [ "${TARGET_ARCH}" == "x86_64" ]
		    then
		        make DEFAULT_CC=clang CROSS="$(dirname $ICC)/" TARGET_FLAGS="$ISDKF" LIBS=-lc++ TARGET_SYS=iOS
		    else
		        make DEFAULT_CC=clang HOST_CC="clang ${MARCH} -arch ${HOST_ARCH}" CROSS="$(dirname $ICC)/" LIBS=-lc++ TARGET_FLAGS="$ISDKF" TARGET_SYS=iOS
		    fi
	      	mv -v ./src/libluajit.a ${BASE_PATH}/lib/libluajit${TARGET_ARCH}.a
	      	JIT_LIBS="${JIT_LIBS} ${BASE_PATH}/lib/libluajit${TARGET_ARCH}.a"
		done  
		  
		lipo -create ${JIT_LIBS} -output ${BASE_PATH}/lib/libluajit.a  2> /dev/null

		echo "Copying headers..."
		rm -rf "${BASE_PATH}/include/"
		mkdir -p "${BASE_PATH}/include/"
		cp -vRL "${CURRENT_PATH}/include/" "${BASE_PATH}/include/"

		cd "${BASE_PATH}"

		echo "base path ${BASE_PATH}"

		echo "Cleaning up..."
    	rm -rf "${CURRENT_PATH}"
		echo "Done"

	CMD

end