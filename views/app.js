(function() {
  var App, AppView, GoalList, GoalModel, GoalView, Goals, Router;

  App = {};

  Router = Backbone.Router.extend({
    routes: {
      '': 'new'
    },
    "new": function() {
      new AppView;
      return console.log('konsole');
    }
  });

  GoalModel = Backbone.Model.extend({
    defaults: function() {
      return {
        goaltitle: '',
        group: '',
        term: '',
        order: Goals.nextOrder()
      };
    },
    toggle: function() {
      this.save({
        done: !this.get('done')
      });
      return this;
    }
  });

  GoalList = Backbone.Collection.extend({
    model: GoalModel,
    SIZE_LIMIT: 100,
    localStorage: new Store('goals'),
    done: function() {
      return this.filter(function(goal) {
        return goal.get('done');
      });
    },
    remaining: function() {
      return this.without.apply(this, this.done());
    },
    nextOrder: function() {
      if (!this.length) return 1;
      return this.last().get('order') + 1;
    },
    comparator: function(goal) {
      return goal.get('order');
    }
  });

  Goals = new GoalList;

  GoalView = Backbone.View.extend({
    tagName: 'li',
    template: _.template($('#item-template').html()),
    events: {
      'click .check': 'toggleDone',
      'dblclick div.goal-text': 'edit',
      'click span.goal-destroy': 'clear',
      'keypress .goal-input': 'updateOnEnter'
    },
    initialize: function() {
      this.model.bind('change', this.render, this);
      return this.model.bind('destroy', this.remove, this);
    },
    render: function() {
      $(this.el).html(this.template(this.model.toJSON()));
      this.setText();
      return this;
    },
    setText: function() {
      var text;
      text = this.model.get('text');
      this.$('.goal-text').text(text);
      this.input = this.$('.goal-text');
      this.input.bind('blur', _.bind(this.close, this)).val(text);
      return this;
    },
    toggleDone: function() {
      this.model.toggle();
      return this;
    },
    edit: function() {
      $(this.el).addClass("editing");
      this.input.focus();
      return this;
    },
    updateOnEnter: function(e) {
      if (e.keyCode === 13) return this.close();
    },
    clear: function() {
      this.model.destroy();
      return this;
    },
    remove: function() {
      $(this.el).remove();
      return this;
    }
  });

  AppView = Backbone.View.extend({
    el: $("#app"),
    events: {
      'keypress #new-goal': 'createOnEnter',
      'keyup #new-goal': 'showTooltip',
      'click .goal-clear': 'clearCompleted'
    },
    initialize: function() {
      this.input = this.$("#new-goal");
      Goals.bind('add', this.addOne, this);
      Goals.bind('reset', this.addAll, this);
      Goals.bind('all', this.render, this);
      return Goals.fetch();
    },
    render: function() {
      return this.updateCount();
    },
    updateCount: function() {
      var size;
      size = Goals.length;
      this.$('#count').text(size);
      this.$('#count-wrapper').toggle(size > 1);
      return this;
    },
    addOne: function(goal) {
      var view;
      console.log('addOne');
      console.log(goal);
      view = new GoalView({
        model: goal
      });
      return this.$('#goal-list').append(view.render().el);
    },
    addAll: function() {
      return Goals.each(this.addOne);
    },
    createOnEnter: function(e) {
      var text;
      text = this.input.val();
      if (!text || e.keyCode !== 13) return;
      Goals.create(console.log('create goal!'), {
        text: text
      });
      this.input.val('');
      return this;
    },
    clearCompleted: function() {
      var _this = this;
      _.each(Goals.done(), function(todo) {
        todo.destroy();
        return true;
      });
      return false;
    },
    showTooltip: function(e) {
      var show, tooltip, val;
      tooltip = this.$(".ui-tooltip-top");
      val = this.input.val();
      tooltip.fadeOut();
      if (this.tooltipTimeout) clearTimeout(this.tooltipTimeout);
      if (val === '' || val === this.input.attr('placeholder')) return;
      show = function() {
        return tooltip.show().fadeIn();
      };
      this.tooltipTimeout = _.delay(show, 1000);
      return true;
    }
  });

  $(function() {
    App.Router = new Router();
    return Backbone.history.start();
  });

}).call(this);
