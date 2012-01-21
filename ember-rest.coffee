###
  Ember-REST.coffee
    by Brandon Fryslie

  Adapted from Javascript by:
    Cerebris Corporation (c) 2012 

  A simple library for RESTful resources for Ember.js

  Requires jQuery

  Licensed under the MIT license:
    http://www.opensource.org/licenses/mit-license.php
###

###
  A model class for RESTful resources

  Extend this class and define the following properties:

  * `name` -- the name used to contain the serialized data in this object's JSON
       representation
  * `properties` -- an array of property names to be returned in this object's
       JSON representation
  * `url` -- (optional) the base url of the resource (e.g. '/contacts/active');
       will default to the `url` for `type`

  You may also wish to override / define the following methods:

  * `serialize()`
  * `serializeProperty(prop)`
  * `deserialize(json)`
  * `deserializeProperty(prop, value)`
  * `validate()`
###

Ember.Resource = Ember.Object.extend
  name:       Ember.require()
  properties: Ember.require()
  url:        Ember.require()


  # Duplicate every property from another resource
  #   
  duplicateProperties: (source) ->
    @set property, source.get property for property in @properties
    return

  # Generate this resource's JSON representation
  # 
  # Override this or `serializeProperty` to provide custom serialization
  # 
  serialize: ->
    rv = {}
    rv[@name][property] = @serializeProperty property for property in @properties
    rv

  # Generate an individual property's JSON representation
  # 
  # Override to provide custom serialization
  # 
  serializeProperty: (property) -> @get property

  # Set this resource's properties from JSON
  # 
  deserialize: (json) ->
    Ember.beginPropertyChanges(@)
    @deserializeProperty property, value for own property, value in json   
    Ember.endPropertyChanges(@)
    @

  # Set an individual property from its value in JSON
  # 
  deserializeProperty: (property) -> @set property, value

  # Create (if new) or update (if existing) record via ajax
  # 
  # Will call validate() if defined for this record
  # 
  # If successful, updates this record's id and other properties
  # by calling `deserialize()` with the data returned.
  # 
  save: ->
    return {
      fail: (f) -> f(error); @
      done: -> @
      always: -> f(); @
    } if (error = @validate?())
  
    jQuery.ajax
      url: @_url()
      data: @serialize()
      dataType: 'json'
      type: if @get('id')? then 'PUT' else 'POST'
      success: (json) => @deserialize json if json?

  # Delete resource via ajax
  # 
  destroy: =>
    jQuery.ajax
      url: @._url()
      dataType: 'json'
      type: 'DELETE'

  # The URL for this resource, based on `url` and `id` (which will be
  # undefined for new resources).
  # 
  _url: -> @url += '/' + id if (id = @get 'id')?

  # A controller for RESTful resources
  # 
  # Extend this class and define the following:
  # 
  # * `type` -- an Ember.Resource class; the class must have a `serialize` method that
  #      returns a JSON representation of the object
  # * `url` -- (optional) the base url of the resource (e.g. '/contacts/active');
  #      will default to the `url` for `type`
  # 

Ember.ResourceController = Ember.ArrayController.extend
  type: Ember.required()
  content: []

  # Create and load a single `Ember.Resource` from JSON
  # 
  load: (json) ->
    @pushObject @get('type').create().deserialize json

  # Create and load `Ember.Resource` objects from a JSON array
  # 
  loadAll: (json) -> @load j for j in json; return
  # Replace this controller's contents with an ajax call to `url`
  # 
  findAll: ->
    jQuery.ajax
      url: @._url()
      dataType: 'json'
      type: 'GET'
      success: (json) =>
        @set 'content', []
        @loadAll json

  # Base URL for ajax calls
  # 
  # Will use the `url` set for this controller, or if that's missing,
  # the `url` specified for `type`.
  # 
  _url: -> @url ? @get('type')::url