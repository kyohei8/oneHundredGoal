_.templateSettings = { interpolate: /__(.+?)__/g }
  
App = {}
Router = Backbone.Router.extend
  routes:
    '': 'new'
  new: ->
    new AppView

#
# Goal Model
#
GoalModel = Backbone.Model.extend
  defaults: ->
    goaltitle: ''
    group: ''
    term: ''
    done: false
    order: Goals.nextOrder()

  toggle: ->
    @save(done: !@get('done'))
    @
    # TODO none use return for function??
     
#
# Goal Collection
#
GoalList = Backbone.Collection.extend
  model: GoalModel
  SIZE_LIMIT: 100
  #store to 'goals'storage
  localStorage: new Store('goals')
  
  shouldAddAt: (indexOfCurrent) ->
    return false if @size() == @SIZE_LIMIT
    return true if indexOfCurrent == @size() - 1
    true
  
  # done's goal item list filter
  done: ->
    @filter (goal)-> goal.get 'done'
  
  # 'doing' goal item list filter
  remaining: ->
    @without.apply(@,@done());
  
  #genetrate index of new goal item
  nextOrder: ->
    return 1 if (!@length);
    @last().get('order') + 1 
  
  #sort 
  comparator:(goal) ->
    return goal.get('order')

# collection of global
Goals = new GoalList

#
# Goal Itemview
#
GoalView = Backbone.View.extend
  tagName: 'li'
  # cache
  template: _.template($('#item-template').html())
  # items event 
  events:
    'click .check'              : 'toggleDone'
    'dblclick div.goal-text'    : 'edit'
    'click span.goal-destroy'   : 'clear'
    'keypress .goal-input'      : 'updateOnEnter'
    'keypress .goal-group-input': 'updateOnEnter'
    'keypress .goal-term-input' : 'updateOnEnter'
    'click #cancel'             : 'cancel'
    'focus .goal-group-input'   : 'suggestGroup'
    'focus .goal-term-input'    : 'suggestTerm'
  
  # change to model to rerender
  initialize: ->
    @model.bind 'change', @render, @
    @model.bind 'destroy', @remove, @
  
  render: ->
    $(@el).html(@template @model.toJSON())
    @input = @$('.goal-input')
    @inputGroup = @$('.goal-group-input')
    @inputTerm = @$('.goal-term-input')
    @setDone()
    @
    
  setDone: ->
    doneclass = if(@model.get('done')) then 'done' else ''
    @$('.goalitem').addClass(doneclass)
    if(@model.get('done'))
      @$('.check').attr('checked','checked')
    else
      @$('.check').removeAttr('checked')
  
  toggleDone: ->
    @model.toggle()
  
  edit: ->
    $(@el).addClass("editing")
    @input.focus()
    
  close: ->
    @model.save(
      goaltitle: @input.val()
      group    : @inputGroup.val()
      term     : @inputTerm.val()
    )
    $(@el).removeClass("editing");
  
  updateOnEnter:(e) ->
    @close() if (e.keyCode == 13)
    
  clear: ->
    @model.destroy()
    
  cancel: ->
    $(@el).removeClass("editing");
    @render()
    
  remove: ->
    $(@el).remove()
  
  suggestGroup: ->
    groups = _.without(_.uniq(Goals.pluck('group')),"")
    $(".goal-group-input").autocomplete(groups)
    
  suggestTerm: ->
    terms = _.without(_.uniq(Goals.pluck('term')),"")
    $(".goal-term-input").autocomplete(terms)


#
# Application
#
AppView = Backbone.View.extend
  el: $("#app")
  #statsTemplate: _.template($('#stats-template').html())
  events:
    'keypress #new-goal':'createOnEnter'
    'keyup #new-goal'   :'showTooltip'
    'click .goal-clear' :'clearCompleted'
    'click #description':'openDescription'
    'click .close':'closeDescription'
    
  initialize: ->
    @input = @$("#new-goal")
    Goals.bind 'add', @addOne, @    
    Goals.bind 'reset', @addAll, @
    Goals.bind 'all', @render, @
    Goals.fetch()
  
  render : ->
    @updateCount()
    
  updateCount: ->
    size = Goals.length
    @$('#count').text(size)
    @$('#count-wrapper').toggle(size > 0)
    @$('.goal-header').toggle(size > 0)    
    @
    
  
  addOne:(goal) ->
    view = new GoalView {model: goal}
    @$('#goal-list').append(view.render().el)
    

  addAll: ->
    Goals.each(@addOne)

  createOnEnter: (e) ->
    text = @input.val()
    return if(not text or e.keyCode isnt 13)
    if @shouldAddRow()
      Goals.create(goaltitle: text)
      @input.val('')
  
  shouldAddRow: ->
    indexOfCurrent = Goals.size()
    Goals.shouldAddAt(indexOfCurrent)

  
  clearCompleted: ->
    _.each Goals.done(), (goal) =>
      goal.destroy()
      true
    false
  
  showTooltip: (e) ->
    tooltip = @$(".ui-tooltip-top")
    val = @input.val()
    tooltip.fadeOut()
    clearTimeout(@tooltipTimeout) if (@tooltipTimeout)
    return if(val is '' or val is @input.attr('placeholder'))
    show = ->
      tooltip.show().fadeIn()
    @tooltipTimeout = _.delay(show,1000)
    true
  
  openDescription:()->
    $(".alert-message").show()
    
  closeDescription:()->
    $(".alert-message").hide()
    
$ ->
  App.Router = new Router()
  Backbone.history.start()
