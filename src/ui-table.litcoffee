#PolymerExpression extensions
`core-list` overrides the model of each repeated row and we lose scope of the parent element.
In this case it would be ui-table.  So we share the filters between `core-list` managed 
elements and `ui-table` managed elements.

    PolymerExpressions.prototype.keys = (o) ->
      Object.keys(o)

    PolymerExpressions.prototype.remove = (arr, remove) ->      
      return arr unless arr?.length and remove?.length
      arr.filter (a) -> !!remove.indexOf a 

    PolymerExpressions.prototype.findTemplate = (userDefinedTemplates, key) ->
      cellTemplate = 'cell-default'
      userDefinedTemplates.array().forEach (i)->
        if i.getAttribute('name') == key
          cellTemplate = "#{key}-column"
      
      cellTemplate

    
#grid-sort-icon
Reactive icon for the current sort direction on the `grid-sort-header`

    Polymer 'grid-sort-icon', {}    

#grid-cell
Light wrapper for cell element
    
    Polymer 'grid-cell', 

      cellClicked: ->
        @fire 'grid-cell-click', @templateInstance.model

      cellDoubleClicked: ->            
        @fire 'grid-cell-double-click', @templateInstance.model

#grid-header
Light wrapper for cell element
    
    Polymer 'grid-header', 

      headerClicked: ->
        @fire 'grid-header-click', @templateInstance.model

      headerDoubleClicked: ->            
        @fire 'grid-header-double-click', @templateInstance.model

#grid-sort-header
An element to handle sorting of a particular column and upating a its sort icon
if present.

    Polymer 'grid-sort-header',

### Change handlers
Handlers that attempt to sync and only dispatch one event by calling `applySort()`.

      directionChanged: ->      
        @applySort()    
        @updateIcon()    

      sortpropChanged: ->
        @applySort()

      colChanged: ->              
        @applySort()

### updateIcon()
Call this to sync your sort icon with the current state

      updateIcon: ->
        sortIcon = @querySelector '[sort-icon]'
        sortIcon?.setAttribute 'direction', @direction        

### applySort()
Syncs `direction`,`sortprop`,`col` and `active`, if they are unset or falsey
no event is dispatched.

_Dispatches:_ `'grid-sort', { direction, prop, col }`

      applySort: ->
        return unless @direction?.length and @sortprop and @active
        
        @fire 'grid-sort',
          direction: @direction
          prop: @sortprop
          col: @col    

### toggleDirection()
Event handler for when the header is clicked.  If the header is not active
then it will suppress `applySort()` from dispatching its event.

      toggleDirection: (event, detail, element) ->        
        @direction = if @direction == 'asc' then 'desc' else 'asc'                
        @active = true        
        @fire 'grid-header-click', @templateInstance.model


#ui-table 
An element that allows you define templates for keys in rows of data and then builds
out a table for you.  Also responds to sorting events that can be dispatched by children.

    Polymer 'ui-table',

### sortFunctions
Comparators for native sort function. These can be overidden though I do not recommend it.

      sortFunctions:
        asc: (a,b) ->
          return 1 if a is undefined or a is '' or a is null
          return -1 if b is undefined or b is '' or b is null
          if typeof(a) is 'string'
            a = a.toLowerCase().trim()
          if typeof(b) is 'string'
            b = b.toLowerCase().trim()
          return 1 if a > b
          return -1 if a < b
          return 0

        desc: (a,b) -> 
          return 1 if a is undefined or a is '' or a is null
          return -1 if b is undefined or b is '' or b is null
          if typeof(a) is 'string'
            a = a.toLowerCase().trim()
          if typeof(b) is 'string'
            b = b.toLowerCase().trim()
          return 1 if a < b
          return -1 if a > b
          return 0

### Change handlers

### sortChanged()
The `sort` property can be changed externally on the node or defined on your templates elements.

      sortChanged: -> @applySort()    

### valueChanged()
When the value is changed it also builds out the headers off of the first row
in the `value` property.  This is likely to change. Sorting is also applied if applicable 
      
      ignoredcolsChanged: ->        
        @_ignoredcols = @ignoredcols
        @_ignoredcols = @ignoredcols.split(',') if typeof(@ignoredcols) == 'string'        
        @rebuildValue()

      rowheightChanged: -> 
        @rebuildValue()

      valueChanged: ->                   
        @rebuildValue()
        @rebuildHeader()
        @applySort()
        @fire 'grid-value-changed'

      updateValue: (event) ->        
        res = event.detail.response
        if @transformResponse
          return @value = @transformResponse res
        @value = res

      rebuildValue: ->        
        @_value = (@value || []).slice(0).map (v,k) =>
          { row: v, rowheight: @rowheight, ignoredcols: @_ignoredcols , userDefinedTemplates: @userDefinedTemplates}        

      rebuildHeader: ->
        @headers = Object.keys @_value.reduce (acc, wrapped) ->          
          Object.keys(wrapped.row).forEach (k) -> acc[k] = true 
          acc
        , {}

### sortColumn()
Change handler for the `grid-sort` event that is dispatched by child elements

      sortColumn: (event, descriptor) ->             
        @sort = descriptor      

### updateHeaders()
Internal function that find all of the child sortable headers and attempts to 
reset their `direction` if they are not active.  For now only single column sort is handled.

      updateHeaders: ->        
        sortables = @shadowRoot?.querySelectorAll "grid-sort-header"                    
        sortables?.array().forEach (sortable) =>    
          console.log sortable.col, @sort.col                
          if sortable.col != @sort.col
            sortable.setAttribute 'active', false
            sortable.direction = ''                     

### applySort()
Internal function that syncs `@_value` and `@sort`.  It updates the header states
and sorts the internal databound collection.

      applySort: ->       
        return unless @_value and @sort

        @updateHeaders()

        @_value.sort (a,b) =>        
          d = @sort
          compare = @sortFunctions[d.direction]                  
          left = @propParser a.row, d.prop
          right = @propParser b.row, d.prop

          compare left, right

### addTemplates(nodes, type)
Internal function to port the user defined templates
      
      addTemplates: (nodes, type) ->
        nodes.getDistributedNodes().array().forEach (t)=>
          col = t.getAttribute 'name'
          t.setAttribute 'id', "#{col}-#{type}"
          @shadowRoot.appendChild t

### ready()
Reads cell and header templates once component is ready for use.

      ready: ->
        @addTemplates @$.columnOverrides, 'column'
        @userDefinedTemplates = @shadowRoot.querySelectorAll 'template[column]'

        cellDefaultOverride = @$['cell-default-override']
          .getDistributedNodes().array()?[0]        

        if cellDefaultOverride
          @shadowRoot.removeChild @$['cell-default']

          t = document.createElement 'template'
          t.setAttribute 'id', 'cell-default'
          t.innerHTML = cellDefaultOverride.innerHTML
          @shadowRoot.appendChild t
                       
  
### propParser(doc,prop):*
Takes a document and dot property string (ex. `'prop1.prop2'`) and returns the value
in the object for the nested property.

      propParser: (doc, prop) ->        
        prop.split('.').reduce (acc, p) -> 
          acc[p]
        , doc
