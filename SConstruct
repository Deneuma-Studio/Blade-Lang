#!/usr/bin/env python
import os
import sys
import struct

from methods import print_error
from methods import print_warning

libname = "BladeLang"

localEnv = Environment(tools=["default"], PLATFORM="")

customs = ["custom.py"]
customs = [os.path.abspath(path) for path in customs]

opts = Variables(customs, ARGUMENTS)
opts.Add(EnumVariable('blade_dev', 'Enable development build features for Blade', 'no', allowed_values=('yes', 'no')))
opts.Update(localEnv)

Help(opts.GenerateHelpText(localEnv))

env = localEnv.Clone()

blade_dev = ARGUMENTS.get('blade_dev', 'no').lower() == 'yes'

if blade_dev:
    env.Append(CPPDEFINES=['DEV_BUILD=1'])
else:
    env.Append(CPPDEFINES=['DEV_BUILD=0'])

# No Need in 4.7
#if env['CC'] != 'cl':
#    if ARGUMENTS.get('platform') == 'web': env.Append(CCFLAGS=['-fwasm-exceptions', '-fexceptions'])
#    else: env.Append(CCFLAGS=['-fexceptions'])

if not (os.path.isdir("godot-cpp") and os.listdir("godot-cpp")):
    print_error("""godot-cpp is not available within this folder, as Git submodules haven't been initialized.
Run the following command to download godot-cpp:

    git submodule update --init --recursive""")
    sys.exit(1)

env = SConscript("godot-cpp/SConstruct", {"env": env, "customs": customs})

# Build libtcc
config_h = "tccbe/config.h"
if os.path.exists(config_h): os.remove(config_h)

if env.get('platform') == 'android' and ARGUMENTS.get('arch', None) == 'arm32':
    print_warning("Building TinyCC for Android(arm32) is experimental and may not function!")

with open(config_h, "w") as f:
    f.write("""#ifndef TCC_CONFIG_H
#define TCC_CONFIG_H
#define TCC_VERSION "blade.edition"
""")
    arch = ARGUMENTS.get('arch', None)
    print(f"[INFO] Configuring TCC for {arch}/{env.get('platform')}")
    if env.get('platform') == 'android': f.write("#define TARGETOS_ANDROID 1\n")
    if arch == "arm32":
        f.write("#define TCC_TARGET_ARM 1\n")
        f.write("#define TCC_ARM_VFP 1\n")
        f.write("#define TCC_ARM_EABI 1\n")
        f.write("#define TCC_ARM_HARDFLOAT 1\n")
        f.write("#define TCC_TARGET_ELF 1\n")
    elif arch == "arm64":
        f.write("#define TCC_TARGET_ARM64 1\n")
        f.write("#define TCC_TARGET_ELF 1\n")
    elif arch == "x86_64":
        f.write("#define TCC_TARGET_X86_64 1\n")
        if env.get('platform') == "android":
            f.write("#define TCC_TARGET_ELF 1\n")
        else:
            f.write("#define TCC_TARGET_PE 1\n")
    elif arch == "x86_32":
        f.write("#define TCC_TARGET_I386 1\n")
        if env.get('platform') == "android":
            f.write("#define TCC_TARGET_ELF 1\n")
        else:
            f.write("#define TCC_TARGET_PE 1\n")
    else:
        # Host Fallback
        is_64 = struct.calcsize("P") == 8
        f.write(f"#define TCC_TARGET_{'X86_64' if is_64 else 'I386'} 1\n")
        f.write("#ifdef _WIN32\n#define TCC_TARGET_PE 1\n#endif\n")
    f.write("#endif\n")

env.Append(CPPPATH=["src/", "tccbe"])
tcc = env.StaticLibrary("tccbe/libtcc", "tccbe/libtcc.c")

sources = Glob("src/*.cpp")

if env["target"] in ["editor", "template_debug"]:
    try:
        doc_data = env.GodotCPPDocData("src/gen/doc_data.gen.cpp", source=Glob("doc_classes/*.xml"))
        sources.append(doc_data)
    except AttributeError:
        print("Not including class reference as we're targeting a pre-4.3 baseline.")

suffix = env['suffix'].replace(".dev", "").replace(".universal", "")
lib_filename = "{}{}{}{}".format(env.subst('$SHLIBPREFIX'), libname, suffix, env.subst('$SHLIBSUFFIX'))

library = env.SharedLibrary(
    "bin/{}/{}".format(env['platform'], lib_filename),
    source=sources,
    LIBS=[tcc] + env.get("LIBS", []),
)

Default(library)
