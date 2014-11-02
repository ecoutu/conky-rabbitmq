conky-rabbitmq
==============

**conky-rabbitmq** is a Lua script that provides data from the RabbitMQ management API to Conky.

## Dependencies

conky-rabbitmq depends on the `socket.http` and `cjson` (https://github.com/mpx/lua-cjson/) Lua libraries. To install on Ubuntu 14.04:

    sudo apt-get install lua-socket lua-cjson

## Configuration

conky-rabbitmq has a few different configuration options. To modify these options, you can change the following values in the conky-rabbitmq.lua script:

* `RABBITMQ_URL` - URL of the RabbitMQ management api, including basic authentication username and password, default is `http://guest:guest@localhost:15672/api/queues`
* `RABBITMQ_COLUMNS` - Comma seperated list of columns/individual queue statistics to be returned from the API; leave as an empty string ("") to return all columns. Each value represents a JSON field, with nested JSON objects/tables seperated by a dot (.). Default is `name,messages,consumers,message_stats.ack_details,message_stats.publish_details,message_stats.deliver_details`
* `RABBITMQ_REFRESH_INTERVAL` - Frequency (in seconds) to refresh data from the RabbitMQ manegement API, default is 5

## Usage

To use conky-rabbitmq, you will first need to load the Lua script in your conkyrc settings (before the TEXT section):

    lua_load /path/to/conky-rabbitmq.lua

conky-rabbitmq provides a number of functions to Conky for displaying queue statistics. Note that some of these functions use Lua [patterns](http://www.lua.org/pil/20.2.html):

* `rabbitmq_stats name field` - Returns the value of `field` for an individual queue named `name`
* `rabbitmq_stats_sum pattern field` - Returns the sum of the values of `field` for all queues whose name matches `pattern`
* `rabbitmq_stats_max pattern field` - Returns the highest value for `field` from all queues whose name matches `pattern`
* `rabbitmq_stats_min pattern field` - Returns the lowest value for `field` from all queues whose name matches `pattern`
* `rabbitmq_next_refresh` - Time (in seconds) until the next data refresh

All of the functions listed above can be used in the Conky TEXT section by using the Conky lua object:

    TEXT
    Notications queue has ${lua rabbitmq_stats notifications messages} messages!
    There are currently ${lua rabbitmq_stats_sum download-page-%d consumers} download page workers

## Graphs

Unfortunately Conky does not allow custom function parameters to be passed with the lua_graph object. If you wish to display graphs for queue statistics, you will need to write a custom Lua function that calls one of the functions above.

### Example

Lua function (added to the conky-rabbitmq.lua script):
  
    function conky_download_page_messages_sum()
      return conky_rabbitmq_stats_sum('download-page-%d', 'messages')
    end
    
Conky TEXT section:

    TEXT
    download page workers: ${lua_graph download_page_messages_sum}
