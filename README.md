#ShaykieBot v0.1

Para funcionar corretamente o PATH é necessario alterar o client para andar sobre fields, para isso antere a seguinte tag
result = g_map.findPath(m_position, destination, 50000, Otc::PathFindAllowNonPathable);

no arquivo localplayer.cpp antes do seguinte codigo
if(std::get<1>(result) != Otc::PathFindResultOk) {
    callLuaField("onAutoWalkFail", std::get<1>(result));


[![Join the chat at https://gitter.im/BenDol/otclient-shaykiebot](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/BenDol/otclient-shaykiebot?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

ShaykieBot is an OTClient bot module that helps with Tibia game-play automation. ShaykieBot is designed to focus on efficiency, stability and safety (from bot-detection). It accomplishes these qualities using, modular style framework, thorough testing, and secure/safe 'game' functions + time delay randomization when logged into Cipsoft Servers.

##Developed by
* BeniS (Ben Dol) - dolb90@gmail.com
* Alexandre do Amaral Severino - alexandre.a.severino@gmail.com

[Contributors](https://github.com/BeniS/otclient-shaykiebot/graphs/contributors)

##License
Licensed under MIT, see LICENSE for more information.

##Showcase
![Screenshot](https://dl.dropbox.com/u/49948294/otclient/shaykiebot_support.png)
![Screenshot](https://dl.dropbox.com/u/49948294/otclient/shaykiebot_afk.png)

##Installation
To install ShaykieBot all you need to do is copy the root directory `otclient-shaykiebot` into the [otclient](https://github.com/edubart/otclient) `/mods` directory and start otclient. If you don't have `otclient-shaykiebot` directory you need to pull this repository (I haven't tagged any releases yet because it's too early in development).

##Contributing
If you are interested in contributing to OTClients ShaykieBot module, feel free to create pull requests. People that would like to be 'repo contributors' can be added once they have made enough satisfying contributions to this project.
