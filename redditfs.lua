#!/usr/bin/env lua

local flu = require 'flu'
local errno = flu.errno
local cjson = require'cjson'
local inspect = require'inspect'

http = require("socket.http")

local subreddits = {'emacs', 'git', 'lua'}
local redditfs = {}

local function mkset(array)
	local set = {}
	for _,flag in ipairs(array) do
		set[flag] = true
	end
	return set
end

local function get_subreddit(s)
  local r, c, h = http.request("http://api.reddit.com/r/".. s .."/hot")
  -- local r, c, h = http.request("http://www.reddit.com/r/".. s .."/.json")
  return cjson.decode(r)
end

function redditfs.readdir(path, filler, fi)
  filler(".") ; filler("..");

  if path == '/' then
    for _,v in ipairs(subreddits) do filler(v) end
  else
    local subreddit = path:match('^/([^/]+)$')
    if subreddit then
      local posts = get_subreddit(subreddit)
      for i,post in ipairs(posts.data.children) do
        filler(post.data.title)
      end
    end
  end
end

function redditfs.getattr(path, st)
	if path=="/" then
		return {
			mode = mkset{ 'dir', 'rusr', 'wusr', 'xusr', 'rgrp', 'xgrp', 'roth', 'xoth' },
			nlink = 2,
		}
	elseif path:match"^/[^/]+$" then
		return {
			mode = mkset{ 'dir', 'rusr', 'wusr', 'xusr', 'rgrp', 'xgrp', 'roth', 'xoth' },
			nlink = 2,
		}
	elseif path:match"^/[^/]+/[^/]+$" then
		return {
			mode = mkset{ 'reg', 'rusr', 'wusr', 'rgrp', 'roth' },
			nlink = 1,
		}
	else
		error(errno.ENOENT)
	end
end


function redditfs.opendir(path, fi)
	if fi.flags.O_WRONLY or fi.flags.O_RDWR then
		error(errno.EACCES)
	end
end

-- print(inspect(get_subreddit('emacs')))

-- require('mobdebug').start()
-- require('mobdebug').start()
-- local posts = get_subreddit('git')
--print(inspect(posts.data.children))

-- for i,v in ipairs(posts.data.children) do
--   print(v.data.title)
-- end

local args = { 'redditfs', ... }

flu.main(args, redditfs)
