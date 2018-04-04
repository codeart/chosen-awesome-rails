# Chosen awesome (with ajax support and "on the fly" options insertion)

A written from scratch library that wraps around default html select controls
and makes them more user friendly (Ruby on Rails package). Out of the box ajax support.

## Usage

### Install chosen-awesome-rails gem

Include `chosen-awesome-rails` in Gemfile

    gem 'chosen-awesome-rails'
    
Then run `bundle install`

### Include javascript assets

Add to your `app/assets/javascripts/application.js`

    //= require chosen

### Include chosen stylesheet assets

Add to your `app/assets/stylesheets/application.css`

    *= require chosen
    
You might also use twitter bootstrap integration by adding

    *= require chosen/bootstrap
    
### Enable chosen
```javascript
$("select").chosen()
```

Default options are:

```javascript
{
  allow_insertion: false, // Allows to add missing options dynamically, e.g. when you
                          // need to show a list of tags allowing users to add missing ones.
  inherit_classes: true,  // Whether chosen should inherit html class names from the
                          // original select element or not.
  option_parser: null,    // A function that should return an object that
                          // will be passed to jQuery to build html option elemets:
                          // $("<option />", parsed_object).
  option_formatter: null  // A function that accepts an option object (jquery selector)
                          // and returns an array of 2 values where one is used
                          // for the dropdown item and another for the choice element
  placeholder: "..."      // Custom placeholder text (by default it will try to read it
                          // from the target element)
}
```

On the fly options insertion:

![Dynamic insertion example]
(http://oi62.tinypic.com/14kb808.jpg)

The option formatter allows to build selects like this one:

![Custom dropdown options]
(http://oi60.tinypic.com/28818i8.jpg)

You can also override text messages with:

```javascript
{
  locale: {
    no_results: "No results found",
    start_typing: "Please start typing",
    add_new: "add new"
  }
}
```

And pass the next ajax options:

```javascript
{
  ajax: {
    url: "where to fetch options",
    type: "get",      // optional
    dataType: "json", // optional
    data: {},         // optional
    async: true,      // optional
    xhrFields: null   // optional
  }
}
```

### JS events

Once chosen is ready it triggers `chosen:ready` event on the target element.
A link to the newly created Chosen object will be saved in the data-chosen attribute
of the target select element.
