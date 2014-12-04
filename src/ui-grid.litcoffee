#PolymerExpression extensions
`core-list` overrides the model of each repeated row and we lose scope of the parent element.
In this case it would be ui-table.  So we share the filters between `core-list` managed 
elements and `ui-table` managed elements.

    PolymerExpressions.prototype.keys = (o) ->
      return unless o #weird timing issues 
      Object.keys(o)
    
#grid-sort-icon
Reactive icon for the current sort direction on the `grid-sort-header`

    Polymer 'grid-sort-icon', {}    

#grid-cell
Light wrapper for cell element
    
    Polymer 'grid-cell', 

      cellClicked: ->
        @fire 'cellclick', @templateInstance.model        

      cellDoubleClicked: ->            
        @fire 'celldblclick', @templateInstance.model

#grid-header
Light wrapper for cell element
    
    Polymer 'grid-header', 

      headerClicked: ->
        @fire 'headerclick', @templateInstance.model

      headerDoubleClicked: ->            
        @fire 'headerdblclick', @templateInstance.model

#grid-sort-header
An element to handle sorting of a particular column and upating a its sort icon
if present.

    Polymer 'grid-sort-header',    

## Change handlers
Handlers that attempt to sync and only dispatch one event by calling `applySort()`.

      directionChanged: ->      
        @applySort()    
        @updateIcon()    

      sortpropChanged: ->
        @applySort()

      colChanged: ->              
        @applySort()

## updateIcon()
Call this to sync your sort icon with the current state

      updateIcon: ->
        sortIcon = @querySelector '[sort-icon]'
        sortIcon?.setAttribute 'direction', @direction        

## applySort()
Syncs `direction`,`sortprop`,`col` and `active`, if they are unset or falsey
no event is dispatched.

_Dispatches:_ `'grid-sort', { direction, prop, col }`

      applySort: ->
        return unless @direction?.length and @sortprop and @active
        
        @fire 'grid-sort',
          direction: @direction
          prop: @sortprop          

## toggleDirection()
Event handler for when the header is clicked.  If the header is not active
then it will suppress `applySort()` from dispatching its event.

      toggleDirection: (event, detail, element) ->        
        @direction = if @direction == 'asc' then 'desc' else 'asc'                
        @active = true


#ui-grid 
An element that allows you define templates for keys in rows of data and then builds
out a table for you.  Also responds to sorting events that can be dispatched by children.

    Polymer 'ui-grid',

## sortFunctions
Comparators for native sort function.

      sortFunctions:
        asc: (a,b) ->
          return 1 if !a? or a is ''
          return -1 if !b? or b is ''
          
          a = a.toLowerCase().trim() if typeof(a) is 'string'          
          b = b.toLowerCase().trim() if typeof(b) is 'string'
            
          return 1 if a > b
          return -1 if a < b
          return 0

        desc: (a,b) -> 
          return 1 if !a? or a is ''
          return -1 if !b? or b is ''
          
          a = a.toLowerCase().trim() if typeof(a) is 'string'            
          b = b.toLowerCase().trim() if typeof(b) is 'string'
            
          return 1 if a < b
          return -1 if a > b
          return 0

## Change handlers

## sortChanged()
The `sort` property can be changed externally on the node or defined on your templates elements.

      sortChanged: -> @applySort()   

## valueChanged()
When the value is changed it also builds out the headers off of the first row
in the `value` property.  This is likely to change. Sorting is also applied if applicable 
      
      rowsChanged: ->
        @removeStaleTemplateRefs()
        @buildTemplateRefs(@headers)
        
        @sort ||= 
          direction: 'asc'
          prop: @headers?[0]

      updateValue: (event) ->  
        res = event.detail.response
        if @transformResponse
          return @value = @transformResponse res
        @value = res        

      buildRows: (value, headers) ->              
        value

      buildHeaders: (value) ->        
        headers = value?.reduce (acc, wrapped) ->         
          Object.keys(wrapped).forEach (k) -> acc[k] = true 
          acc
        , {}

        Object.keys(headers || {})        

      buildTemplateRefs: ->
        overrideTemplate = @$['column-override'].getDistributedNodes().array()
        overriddenColumns = overrideTemplate.map (t) -> t.getAttribute 'name'
        overriddenColumns.forEach (o) =>
          col = o.getAttribute 'name'          
          o.setAttribute 'id', "#column-#{col}"
          o.setAttribute 'removable', ''
          @shadowRoot.appendChild t
        
        usesDefault = @headers.filter (i) -> overriddenColumns.indexOf(i) < 0        
        usesDefault.forEach (col) =>
          t = document.createElement 'template'          
          t.setAttribute 'id', "column-#{col}"
          t.setAttribute 'removable', ''
          t.setAttribute 'ref', 'column-default'          
          @shadowRoot.appendChild t

      buildDefaultCellRef: ->
        colDefault = @$['column-default-override']
          .getDistributedNodes().array()?[0]    

        if colDefault
          @shadowRoot.removeChild @$['column-default']
          t = document.createElement 'template'
          t.setAttribute 'id', 'column'
          t.innerHTML = cellDefaultOverride.innerHTML
          @shadowRoot.appendChild t

      removeStaleTemplateRefs: ->
        @$['[removable]']?.array().forEach (t) =>
          @shadowRoot.removeChild t


## sortColumn()
Change handler for the `grid-sort` event that is dispatched by child elements

      sortColumn: (event, descriptor) ->             
        @sort = descriptor      

## updateHeaders()
Internal function that find all of the child sortable headers and attempts to 
reset their `direction` if they are not active.  For now only single column sort is handled.

      updateHeaders: ->        
        sortables = @shadowRoot?.querySelectorAll "grid-sort-header"                    
        sortables?.array().forEach (sortable) =>               
          if sortable.col != @sort.prop
            sortable.setAttribute 'active', false
            sortable.direction = ''  
          else                    
            sortable.setAttribute 'active', true
            sortable.direction = @sort.direction

## applySort()
Internal function that syncs `@_value` and `@sort`.  It updates the header states
and sorts the internal databound collection.

      applySort: ->  
        debugger     
        return unless @rows and @sort

        @updateHeaders()

        @rows.sort (a,b) =>        
          d = @sort
          compare = @sortFunctions[d.direction]                  
          left = @propParser a, d.prop
          right = @propParser b, d.prop

          compare left, right

## ready()
Reads cell defaut and swaps out template is necessary.

      ready: ->
        @ignoredcols ||= []
        @buildDefaultCellRef()

## propParser(doc,prop):*
Takes a document and dot property string (ex. `'prop1.prop2'`) and returns the value
in the object for the nested property.

      propParser: (doc, prop) ->        
        prop.split('.').reduce (acc, p) -> 
          acc[p]
        , doc  

      computed: 
        rows: 'buildRows(value,headers)'
        headers: 'buildHeaders(value)'
