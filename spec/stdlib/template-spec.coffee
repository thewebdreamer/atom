Template = require 'template'

describe "Template", ->
  describe "toView", ->
    view = null

    beforeEach ->
      subviewTemplate = class extends Template
        content: (params) ->
          @div =>
            @h2 { outlet: "header" }, params.title
            @div "I am a subview"

      template = class extends Template
        content: (attrs) ->
          @div =>
            @h1 { outlet: 'header' }, attrs.title
            @list()
            @subview 'subview', subviewTemplate.build(title: "Subview")

        list: ->
          @ol =>
            @li outlet: 'li1', click: 'li1Clicked', class: 'foo', "one"
            @li outlet: 'li2', keypress:'li2Keypressed', class: 'bar', "two"

        viewProperties:
          initialize: (attrs) ->
            @initializeCalledWith = attrs
          foo: "bar",
          li1Clicked: ->,
          li2Keypressed: ->

      view = template.build(title: "Zebra")

    describe ".build(attributes)", ->
      it "generates markup based on the content method", ->
        expect(view).toMatchSelector "div"
        expect(view.find("h1:contains(Zebra)")).toExist()
        expect(view.find("ol > li.foo:contains(one)")).toExist()
        expect(view.find("ol > li.bar:contains(two)")).toExist()

      it "extends the view with viewProperties, calling the 'constructor' property if present", ->
        expect(view.constructor).toBeDefined()
        expect(view.foo).toBe("bar")
        expect(view.initializeCalledWith).toEqual title: "Zebra"

      it "wires references for elements with 'outlet' attributes", ->
        expect(view.li1).toMatchSelector "li.foo:contains(one)"
        expect(view.li2).toMatchSelector "li.bar:contains(two)"

      it "constructs and wires outlets for subviews", ->
        expect(view.subview).toExist()
        expect(view.subview.find('h2:contains(Subview)')).toExist()

      it "does not overwrite outlets on the superview with outlets from the subviews", ->
        expect(view.header).toMatchSelector "h1"
        expect(view.subview.header).toMatchSelector "h2"

      it "binds events for elements with event name attributes", ->
        spyOn(view, 'li1Clicked').andCallFake (event, elt) ->
          expect(event.type).toBe 'click'
          expect(elt).toMatchSelector 'li.foo:contains(one)'

        spyOn(view, 'li2Keypressed').andCallFake (event, elt) ->
          expect(event.type).toBe 'keypress'
          expect(elt).toMatchSelector "li.bar:contains(two)"

        view.li1.click()
        expect(view.li1Clicked).toHaveBeenCalled()
        expect(view.li2Keypressed).not.toHaveBeenCalled()

        view.li1Clicked.reset()

        view.li2.keypress()
        expect(view.li2Keypressed).toHaveBeenCalled()
        expect(view.li1Clicked).not.toHaveBeenCalled()

