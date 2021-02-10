((E, $) ->
  'use strict'

  Vue.use(VueResource);
  Vue.http.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  Vue.component 'list-input',
    props: ['label', 'top_hint', 'url', 'model', 'element', 'value_label', 'options', 'aid', 'require', 'errors', 'disable']
    template: """
      <div class='control-group'>
        <label class='control-label' v-bind:class='{ required: require, optional: !require }'>
          <abbr title='Obligatoire' v-if='require'>
            *
          </abbr>
          {{ label }}
        </label>
        <div class='controls'>
          <div class='selector'>
            <p class='help-block'>{{ top_hint }}</p>
            <input class='selector-search' type='text' ref='input' @keyup='listOfElement(true)' v-model='itemName' v-bind:class='{has_error: errors != null}' :disabled='disable'></input>
            <a class='selector-dropdown btn btn-default dropdown-toggle sr-only' @click.prevent='listOfElement(false)' :disabled='disable'></a>
            <p class='errors text-danger' v-if='errors != null'>{{ errors }}</p>
            <div class='items-menu choices-selector activites-list' v-if='showList' v-click-outside='switchModal'>
              <ul class='items-list'>
                <li class='item pointer-item' v-for='item in list' @click='updateValue(item)''>{{ item.label || item.name }}</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    """,
    data: ->
      showList: false,
      list: [],
      listOptions: {},
    created: ->
      this.itemName = this.value_label
    methods:
      listOfElement: (search) ->
        this.$http.get(this.url, params: { q: this.itemName if search, options: this.options }).then (( response) =>
          this.list = response.body
          if search
            this.showList = true
          else
            this.switchModal()
          )
        if search && this.itemName.length == 0
          this.$emit('input', null)
      updateValue: (item) ->
        this.$emit('input', item.id)
        this.$emit('updated', { item: item, aid: this.aid })
        this.itemName = item.label || item.name
        this.switchModal()
      switchModal: ->
        # Show or hide modal
        this.showList = !this.showList

) ekylibre, jQuery
