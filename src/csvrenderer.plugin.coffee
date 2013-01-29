module.exports = (BasePlugin) ->
    class CsvrendererPlugin extends BasePlugin
        name: 'csvrenderer'

        render: (opts,next) ->
            config = @config
            docpad = @docpad
            {inExtension,outExtension} = opts
            if inExtension in ['csv'] and outExtension in ['html']
                csv = require 'csv'
                docpad.log('debug', 'CsvrendererPluging called')
                html = '<table>'
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
            else
                next()
            