#!/usr/bin/env bash

#  2024-2024, Bruno Gonçalves <www.biglinux.com.br>
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
#  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
#  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Define a list of known DLLs and their descriptions
dllList="
amstream  amstream.dll
atmlib  atmlib.dll
avifil32  avifil32.dll
cabinet  cabinet.dll
comctl32  comctl32.dll
crypt32  crypt32.dll
crypt32_winxp  crypt32.dll
binkw32  binkw32.dll
d3dcompiler_42  d3dcompiler_42.dll
d3dcompiler_43  d3dcompiler_43.dll
d3dcompiler_46  d3dcompiler_46.dll
d3dcompiler_47  d3dcompiler_47.dll
d3drm  d3drm.dll
d3dx9  d3dx9_43.dll
d3dx9_24  d3dx9_24.dll
d3dx9_25  d3dx9_25.dll
d3dx9_26  d3dx9_26.dll
d3dx9_27  d3dx9_27.dll
d3dx9_28  d3dx9_28.dll
d3dx9_29  d3dx9_29.dll
d3dx9_30  d3dx9_30.dll
d3dx9_31  d3dx9_31.dll
d3dx9_32  d3dx9_32.dll
d3dx9_33  d3dx9_33.dll
d3dx9_34  d3dx9_34.dll
d3dx9_35  d3dx9_35.dll
d3dx9_36  d3dx9_36.dll
d3dx9_37  d3dx9_37.dll
d3dx9_38  d3dx9_38.dll
d3dx9_39  d3dx9_39.dll
d3dx9_40  d3dx9_40.dll
d3dx9_41  d3dx9_41.dll
d3dx9_42  d3dx9_42.dll
d3dx9_43  d3dx9_43.dll
d3dx11_42  d3dx11_42.dll
d3dx11_43  d3dx11_43.dll
d3dx10  d3dx10_33.dll
d3dx10_43  d3dx10_43.dll
d3dxof  d3dxof.dll
dbghelp  dbghelp.dll
devenum  devenum.dll
dinput  dinput.dll
dinput8  dinput8.dll
directmusic  dmusic.dll
directplay  dplayx.dll
dpvoice  dpvoice.dll dpvvox.dll dpvacm.dll
dsdmo  dsdmo.dll
dxtrans  dxtrans.dll
dxvk0054  d3d11.dll dxgi.dll
dxvk0060  d3d11.dll dxgi.dll
dxvk0061  d3d11.dll dxgi.dll
dxvk0062  d3d11.dll dxgi.dll
dxvk0063  d3d11.dll dxgi.dll
dxvk0064  d3d11.dll dxgi.dll
dxvk0065  d3d11.dll dxgi.dll
dxvk0070  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0071  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0072  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0080  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0081  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0090  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0091  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0092  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0093  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0094  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0095  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk0096  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1000  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1001  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1002  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1003  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1011  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1020  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1021  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1022  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1023  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1030  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1031  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1032  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1033  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1034  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1040  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1041  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1042  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1043  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1044  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1045  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1046  d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1050  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1051  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1052  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1053  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1054  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1055  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1060  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1061  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1070  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1071  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1072  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1073  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1080  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1081  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1090  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1091  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1092  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1093  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1094  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1100  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1101  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1102  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk1103  d3d9.dll d3d10.dll d3d10_1.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk2000  d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk2010  d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk2020  d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk2030  d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk  d3d9.dll d3d10core.dll d3d11.dll dxgi.dll
dxvk_nvapi0061  nvapi.dll nvapi64.dll
vkd3d  d3d12.dll d3d12core.dll
dmusic32  dmusic32.dll
dmband  dmband.dll
dmcompos  dmcompos.dll
dmime  dmime.dll
dmloader  dmloader.dll
dmscript  dmscript.dll
dmstyle  dmstyle.dll
dmsynth  dmsynth.dll
dmusic  dmusic.dll
dswave  dswave.dll
dx8vb  dx8vb.dll
dxdiagn  dxdiagn.dll
dxdiagn_feb2010  dxdiagn.dll
dsound  dsound.dll
esent  esent.dll
faudio1901  FAudio.dll
faudio1902  FAudio.dll
faudio1903  FAudio.dll
faudio1904  FAudio.dll
faudio1905  FAudio.dll
faudio1906  FAudio.dll
faudio190607  FAudio.dll
faudio  FAudio.dll
galliumnine02  d3d9-nine.dll ninewinecfg.exe
galliumnine03  d3d9-nine.dll ninewinecfg.exe
galliumnine04  d3d9-nine.dll ninewinecfg.exe
galliumnine05  d3d9-nine.dll ninewinecfg.exe
galliumnine06  d3d9-nine.dll ninewinecfg.exe
galliumnine07  d3d9-nine.dll ninewinecfg.exe
galliumnine08  d3d9-nine.dll ninewinecfg.exe
galliumnine09  d3d9-nine.dll ninewinecfg.exe
galliumnine  d3d9-nine.dll ninewinecfg.exe
gdiplus  gdiplus.dll
gdiplus_winxp  gdiplus.dll
glidewrapper  glide3x.dll
gfw  xlive.dll
dirac  DiracDecoder.dll
ffdshow  ff_liba52.dll
hid  hid.dll
icodecs  ir50_32.dll
iertutil  iertutil.dll
itircl  itircl.dll
itss  itss.dll
cinepak  iccvid.dll
jet40  dao360.dll
lavfilters  avfilter-lav-7.dll
lavfilters702  avfilter-lav-6.dll
mdx  microsoft.directx.dll
mf  mf.dll
mfc40  mfc40.dll
mfc70  mfc70.dll
msaa  oleacc.dll oleaccrc.dll msaatext.dll
msacm32  msacm32.dll
msasn1  msasn1.dll
msctf  msctf.dll
msdelta  msdelta.dll
msls31  msls31.dll
msftedit  msftedit.dll
msvcrt40  msvcrt40.dll
msxml3  msxml3.dll
msxml4  msxml4.dll
msxml6  msxml6.dll
ogg  AxPlayer.dll
ole32  ole32.dll
oleaut32  oleaut32.dll
openal  OpenAL32.dll
pdh  pdh.dll
pdh_nt4  pdh.dll
pngfilt  pngfilt.dll
prntvpt  prntvpt.dll
qasf  qasf.dll
qcap  qcap.dll
qdvd  qdvd.dll
qedit  qedit.dll
quartz  quartz.dll
quartz_feb2010  quartz.dll
riched20  riched20.dll
riched30  riched20.dll msls31.dll
sapi  sapi.dll
sdl  SDL.dll
secur32  secur32.dll
setupapi  setupapi.dll
uiribbon  uiribbonres.dll
updspapi  updspapi.dll
urlmon  urlmon.dll
usp10  usp10.dll
vb3run  Vbrun300.dll
vb4run  Vb40032.dll
vb5run  msvbvm50.dll
vb6run  msvbvm60.dll
vcrun6  mfc42.dll
mfc42  mfc42u.dll
msvcirt  msvcirt.dll
vcrun6sp6  mfc42.dll
vcrun2003  msvcp71.dll
mfc71  mfc71.dll
vcrun2005  mfc80.dll
mfc80  mfc80.dll
vcrun2008  msdia90.dll
mfc90  mfc90.dll
vcrun2010  mfc100.dll
mfc100  mfc100u.dll
vcrun2012  mfc110.dll
mfc110  mfc110u.dll
vcrun2013  mfc120.dll
mfc120  mfc120u.dll
vcrun2015  mfc140.dll
mfc140  mfc140u.dll
vcrun2017  mfc140.dll
vcrun2019  mfc140.dll
ucrtbase2019  ucrtbase.dll
vcrun2022  vcruntime140.dll
vjrun20  VJSharpSxS10.dll
webio  webio.dll
windowscodecs  WindowsCodecs.dll
winhttp  winhttp.dll
wininet  wininet.dll
wininet_win2k  wininet.dll
wmi  wbemcore.dll
wmv9vcm  wmv9vcm.dll
wsh57  scrrun.dll
xact  xactengine2_0.dll
xact_x64  xactengine2_0.dll
xinput  xinput1_1.dll
xmllite  xmllite.dll
xna31  Microsoft.Xna.Framework.Game.dll
xna40  XnaNative.dll
ie6  iedetect.dll
"

# Function to display help/usage instructions
show_help() {
    echo "Usage: $0 <file-path>"
    echo "This script checks for DLL dependencies in the specified file and matches them against a known list."
    echo ""
    echo "Options:"
    echo "  -h, --help    Display this help message and exit."
    echo ""
    echo "Example:"
    echo "  $0 /path/to/your/file.exe"
}

# Check if no argument is provided or if the argument is -h or --help
if [[ -z "$1" || "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Process the file to find DLL dependencies
for depends in $(strings "$1" | grep -i '\.dll$' | sort -u); do
    echo "$dllList" | grep "\b$depends\b"
done
