module.exports = (BasePlugin) ->
    balUtil = require('bal-util')
    
    class CsvrendererPlugin extends BasePlugin
        name: 'csvrenderer'

        config:
            tableClass: 'table table-striped'
                    

        convertToCsvPath: (path) ->
            if path.match(/\.html$/) then path.replace(/\.html$/, '.csv') else path+'.csv'

        renderBefore: (opts,next) ->
            docpad = @docpad
            csvRenderer = @
            {collection, templateData} = opts
            
            csvModels = collection.findAll({extension: 'csv'})
            csvModels.forEach (file) ->
                url = file.get('url')
                csvUrl = csvRenderer.convertToCsvPath(url)
                file.setMeta({'csvUrl': csvUrl})

            next()
        render: (opts,next) ->

            {inExtension,outExtension} = opts
            
            if inExtension in ['csv'] and outExtension in ['html']
                @renderAsTable(opts, next)
            else if inExtension in ['csv'] and outExtension in ['json']
                @renderAsJson(opts, next)
            else
                next()


        renderAsTable: (opts, next) ->
            docpad = @docpad
            csvRenderer = @
            config = @config

            csv = require 'csv'
            docpad.log('debug', 'CsvrendererPluging called')
            html = "<table class=\"#{config.tableClass}\">"
            
            csv().from(opts.content).on 'end' ,() =>
                html += '</tbody></table>'
                opts.content = html
                docpad.log('debug', 'Csvrenderer: '+html)
                docpad.log('debug', 'Csvrenderer parse end')
                next()
            .on 'record', (record, index) =>
                firstLine = 0
                secondLine = 1
                tag = if index == firstLine then 'th' else 'td'
                htmlfiedColumns = ( '<'+tag+'>' + item + '</'+tag+'>' for item in record)
                line = '<tr>' + htmlfiedColumns.join('') + '</tr>'
                line = if index == firstLine then '<thead>' + line + '</thead>' else line
                line = if index == secondLine then '<tbody>' + line else line
                html += line
            .on 'error', (error) =>
                opts.content = 'error on '+error
                docpad.log('error', 'Csvrenderer parse error'+error)
                next()

        renderAsJson: (opts, next) ->
            docpad = @docpad
            csvRenderer = @

            csv = require 'csv'
            docpad.log('debug', 'CsvrendererPluging called')
            csv().from(opts.content)
            .on 'error', (error) =>
                opts.content = 'error on '+error
                docpad.log('error', 'Csvrenderer parse error'+error)
                next()
            .to .array (data, count) =>
                opts.content = JSON.stringify(data)
                next()


        writeAfter: (opts,next) ->
            docpad = @docpad
            config = @config
            csvRenderer = @
            {collection} = opts
            
            csvModels = collection.findAll({extension: 'csv'})
            csvModels.forEach (file) ->
                csvPath = file.get('outPath').replace(/\.html$/, '.csv')
                balUtil.writeFile csvPath, file.getContent(), (err) ->
                    return next?(err) if err
                    docpad = @docpad
                    docpad.log('debug', "wrote csv file #{csvPath}")

            next()
