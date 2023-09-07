fx_version 'cerulean'
game 'gta5'

author 'AiReiKe'
description 'Cyber City Test Drive'

shared_scripts {
    '@es_extended/locale.lua',
    '@es_extended/imports.lua',
    'locales/*.lua',
    'config.lua'
}

client_script 'client.lua'
server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}
