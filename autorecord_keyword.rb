#!/usr/bin/ruby
# -*- coding: utf-8 -*-
#$KCODE ='u' #1.9.1では不要

require 'rubygems'
require 'mechanize'

#認証用アカウント情報
#テレビ王国を使う場合
tvAccount =''  #テレビ王国のユーザーアカウントを入力
tvPassword ='' #テレビ王国のパスワードを入力

search_word = ARGV[0]
puts "「#{search_word}」を含む番組を検索しています。"

#テレビ王国へのログイン処理
agent = Mechanize.new
page = agent.get('https://www.so-net.ne.jp/tv/myepg/login/seamless-login.cgi')
page.form['mailAddress'] = tvAccount #ログインID入力
page.form['password'] = tvPassword #パスワード入力
page.form.click_button

#録画済みの一覧を取得
record_titles = Array.new
record_alltitles = Array.new
i =0
begin
  agent.get('http://tv.so-net.ne.jp/m/dapRecordedReservations.action?index='+ i.to_s)
#stripで空白削除
  record_titles = agent.page.root.search('h2').map{|e| e.inner_text.strip}
  record_alltitles = record_alltitles + record_titles
  i += 20
end while agent.page.root.search('p.utileListProperty').size == 20 

#予約済みの一覧を取得
reserve_titles = Array.new
reserve_alltitles = Array.new
i=0
begin
  agent.get('http://tv.so-net.ne.jp/m/dapReservations.action?index='+ i.to_s)
  reserve_titles = agent.page.root.search('a').map{|e| e.inner_text.strip}
  reserve_alltitles = reserve_alltitles + reserve_titles
  i += 20
end while agent.page.root.search('p.utileListProperty').size == 20

#検索
page = agent.get('http://tv.so-net.ne.jp/search/')
search_form = page.form('headerSearchForm')

#search_word（検索用キーワード）を検索欄に入れて投稿する
search_form['condition.keyword'] = search_word
agent.submit(search_form)

begin
  search_title_url = agent.page.link_with(:href => /\/schedule\/..*/ ).href
  search_title_text = agent.page.link_with(:href => /\/schedule\/..*/ ).text
  #search_title_text = agent.page.root.search('a')

  puts search_title_url #予約対象のURL
  puts search_title_text #予約対象のタイトル
  rescue
    puts "該当する番組が見つかりませんでした。"
  else

#予約番組の重複チェック
  alltitles = record_alltitles + reserve_alltitles
  if alltitles.index(search_title_text) == nil then

#HDDレコーダーへの予約処理
    agent.page.links.find{|e| e.node['title'] == 'HDDレコーダー'}.click
    yoyaku = agent.page.form_with(:name => 'dapReservationAddingOpened')
    yoyaku.click_button(yoyaku.button_with(:value => 'リモート予約実行'))
      puts "#{search_title_text}を予約しました。"
    else
      puts "番組が重複しているので予約を実行しませんでした。"
  end
end