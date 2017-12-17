===============================
Age of Empires - Message Helper
===============================

AgeKey is a small program helping to enter cheat codes quickly in games of the
"Age of Empires" game series.

It was written by `Nico Bendlin`_ in 2000 as can be still gleaned from the
included ``info.txt``.

So the title Nico gave it "Message Helper" is a euphemism, because the messages
it was meant for mostly are cheat codes. So one could just as well call it a
cheat helper.

Much later I extended it for "Age of Mythology" and its extension "The Titans"
and fixed it recently to have particular extension-specific cheat codes loaded
for the latter. But this was little work to speak of.

This repository and its `download area`_ exists mainly for the **code-signed**
copy of the program.

It's a simple program embedding a keyboard hook DLL which, when triggered by the
respective hotkeys assigned to individual cheat codes, will copy the cheat code
to the clipboard, send an Enter key to open the chat and send Ctrl+V to paste
the cheat code. This whole process is so fast you won't even see the chat box
in most cases when using this method.

By default the program will start with a simple dialog box offering you to load
a set of (hardcoded) cheats from the main menu. Pick the game in question, edit
any of the cheat codes if and when desired and then press the ``Activate keys``
button to have the embedded hook DLL take effect.

By default all predefined cheat sets will assign one cheat per key combination
Ctrl+Fx, where Fx is one of the function keys (F1..F12) on your keyboard.

The program was written in Delphi 5 and the version distributed via the download
section is built with Delphi 7 Pro and code-signed by me (both the embedded DLL
and the EXE containing it).

.. _Nico Bendlin: http://www.bendlins.de/nico/
.. _download area: https://bitbucket.org/assarbad/agekey/downloads/
