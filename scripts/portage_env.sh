# use as many cores as available
export MAKEOPTS="-j$(nproc)"

# USE
# Look at CPU and return all actually available USE flags
get_cpu_use() {
        AVAILABLE_USE="mmx mmxext sse sse2 sse3 ssse3 sse4 sse4_1 avx 3dnow 3dnowext"
        CPU_FLAGS=$(cat /proc/cpuinfo | grep flags | cut -d\  -f2- | uniq)

        _USE=""
        for f in ${AVAILABLE_USE}; do
                if [ "$CPU_FLAGS" != "${CPU_FLAGS/$f/}" ]; then
                        _USE="$_USE $f"
                fi
        done
        echo $_USE
}

export USE=$(get_cpu_use)
