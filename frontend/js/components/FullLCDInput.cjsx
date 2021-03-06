_ = require('lodash')

insertAt = (str, pos, char) ->
  str.substr(0, pos) + char + str.substr(pos)

deleteAt = (str, pos) ->
  str.substr(0, pos) + str.substr(pos + 1)

replaceAt = (str, pos, char) ->
  insertAt(deleteAt(str, pos),
           pos,
           char
  )

module.exports = React.createClass(
  displayName: 'FullLCDInput'
  mixins: [React.addons.LinkedStateMixin]
  _displayCursorChar: 'ĉ'

  getInitialState: ->
    scrollLeft: 0
    focused: false
    cursorPosition: 0

  # Updating this component is expensive (it always touches the DOM),
  # and there are no props we need to react to, so we avoid updating at
  # 60fps with the rest of the game screen.

  shouldComponentUpdate: (nextProps, nextState) ->
    !_.isEqual(@state, nextState) or (@props.value != nextProps.value)

  # I'm really sorry about this. Honestly, I am. I tried every other
  # possible way, but in the end I had no choice. The only way to find out
  # when the user scrolls the input field, or moves the cursor,
  # is to poll CONSTANTLY, checking for changes to the scroll offset
  # and selection values the whole time.
  #
  # I am deeply ashamed of what I've done here.

  componentDidMount: ->
    if @props.onChange?
      poll = =>
        if @isMounted()
          input = @refs.input.getDOMNode()
          @setState(
            scrollLeft: input.scrollLeft
            focused: input == document.activeElement
            selectionStart: input.selectionStart
            selectionEnd: input.selectionEnd
          )
          @pollingTimerId = window.requestAnimationFrame(poll)
      poll()

      @refs.input.getDOMNode().focus()
      @refs.input.getDOMNode().setSelectionRange(@props.value.length, @props.value.length)

  startBlink: ->
    @stopBlink()
    @setState(cursorBlink: true)
    @blinkAnimation = setInterval(=>
      @setState(cursorBlink: !@state.cursorBlink)
    , 500)

  stopBlink: ->
    if @blinkAnimation
      clearInterval(@blinkAnimation)
      @blinkAnimation = null

  handleFocus: ->
    @startBlink() if @props.onChange?

  handleKeyDown: ->
    @startBlink() if @props.onChange?

  handleBlur: ->
    @stopBlink() if @props.onChange?

  handleChange: (e) ->
    @props.onChange?(e.target.value)

  componentDidUpdate: ->
    if @props.onChange?
      @refs.displayBackground.getDOMNode().scrollLeft = @state.scrollLeft
      @refs.displayText.getDOMNode().scrollLeft = @state.scrollLeft

  displayText: ->
    text = @props.value + '  '
    if @state.focused
      if @state.selectionStart == @state.selectionEnd
        if @state.cursorBlink
          text = replaceAt(text, @state.selectionStart, @_displayCursorChar)
      else
        for i in [@state.selectionStart .. @state.selectionEnd - 1]
          text = replaceAt(text, i, @_displayCursorChar)
    text

  render: ->
    <div className={React.addons.classSet(expression: true, focused: @state.focused)}>
      <div className='expression-inner-wrapper'>
        <div className='expression-background-text' ref='displayBackground' >{(@_displayCursorChar for i in [1..100]).join('')}</div>
        <div className='expression-display-text' ref='displayText' >{@displayText()}</div>
        <input 
          ref='input'
          type='text'
          value={@props.value}
          onChange={@handleChange}
          onFocus={@handleFocus}
          onBlur={@handleBlur}
          onKeyDown={@handleKeyDown}
          />
      </div>
    </div>
)