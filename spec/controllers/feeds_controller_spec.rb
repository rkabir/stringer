require "spec_helper"

app_require "controllers/feeds_controller"

describe "FeedsController" do
  let(:feeds) { [FeedFactory.build, FeedFactory.build] }

  describe "GET /feeds" do
    it "renders a list of feeds" do
      FeedRepository.should_receive(:list).and_return(feeds)

      get "/feeds"

      page = last_response.body
      page.should have_tag("ul#feed-list")
      page.should have_tag("li.feed", count: 2)
    end

    it "displays message to add feeds if there are none" do
      FeedRepository.should_receive(:list).and_return([])

      get "/feeds"

      page = last_response.body
      page.should have_tag("#add-some-feeds")
    end
  end

  describe "POST /delete_feed" do
    it "deletes a feed given the id" do
      FeedRepository.should_receive(:delete).with("123")

      post "/delete_feed", feed_id: 123
    end
  end

  describe "GET /add_feed" do
    context "when the feed url is valid" do
      let(:feed_url) { "http://example.com/" }
      let(:feed) { stub }

      it "adds the feed and queues it to be fetched" do
        AddNewFeed.should_receive(:add).with(feed_url).and_return(feed)
        FetchFeeds.should_receive(:enqueue).with([feed])

        post "/add_feed", feed_url: feed_url

        last_response.status.should be 302
        URI::parse(last_response.location).path.should eq "/"
      end
    end

    context "when the feed url is invalid" do
      let(:feed_url) { "http://not-a-feed.com/" }

      it "adds the feed and queues it to be fetched" do
        AddNewFeed.should_receive(:add).with(feed_url).and_return(nil)

        post "/add_feed", feed_url: feed_url

        page = last_response.body
        page.should have_tag(".error")
      end
    end
  end

  describe "GET /import" do
    it "displays the import options" do
      get "/import"

      page = last_response.body
      page.should have_tag("input#opml_file")
      page.should have_tag("a#skip")
    end
  end

  describe "POST /import" do
    let(:opml_file) { Rack::Test::UploadedFile.new("spec/sample_data/subscriptions.xml", "application/xml") }

    it "parse OPML and starts fetching" do
      ImportFromOpml.should_receive(:import).once

      post "/import", {"opml_file" => opml_file}

      last_response.status.should be 302
      URI::parse(last_response.location).path.should eq "/setup/tutorial"
    end
  end

  describe "GET /export" do
    let(:some_xml) { "<xml>some dummy opml</xml>"}
    before { Feed.stub(:all) }

    it "returns an OPML file" do
      ExportToOpml.any_instance.should_receive(:to_xml).and_return(some_xml)
    
      get "/export"

      last_response.body.should eq some_xml
      last_response.header["Content-Type"].should include 'xml'
    end
  end
end