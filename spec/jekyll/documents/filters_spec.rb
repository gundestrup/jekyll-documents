# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jekyll::Documents::Filters do
  let(:filter_class) do
    Class.new do
      include Jekyll::Documents::Filters
    end
  end
  let(:filter) { filter_class.new }

  describe "#documents_slugify" do
    it "converts spaces to hyphens" do
      result = filter.documents_slugify("Board Meeting Minutes")
      expect(result).to eq("board-meeting-minutes")
    end

    it "removes special characters" do
      result = filter.documents_slugify("Board@Meeting#2026!")
      expect(result).to eq("boardmeeting2026")
    end

    it "handles Danish characters by default" do
      result = filter.documents_slugify("Møde om Økonomi")
      expect(result).to eq("moede-om-oekonomi")
    end

    it "can disable Danish character mapping" do
      result = filter.documents_slugify("Møde om Økonomi", true, false)
      expect(result).to eq("mde-om-konomi")
    end

    it "downcases by default" do
      result = filter.documents_slugify("BOARD MEETING")
      expect(result).to eq("board-meeting")
    end

    it "can preserve case" do
      result = filter.documents_slugify("Board Meeting", false)
      expect(result).to eq("Board-Meeting")
    end

    it "collapses multiple hyphens" do
      result = filter.documents_slugify("Board---Meeting")
      expect(result).to eq("board-meeting")
    end

    it "strips leading and trailing whitespace" do
      result = filter.documents_slugify("  Board Meeting  ")
      expect(result).to eq("board-meeting")
    end
  end

  describe "#documents_title_from_filename" do
    it "extracts title from YYYY-MM-DD_Title format" do
      result = filter.documents_title_from_filename("2026-03-01_Board_Meeting")
      expect(result).to eq("Board Meeting")
    end

    it "handles multiple underscores in title" do
      result = filter.documents_title_from_filename("2026-03-01_Board_Meeting_Minutes")
      expect(result).to eq("Board Meeting Minutes")
    end

    it "returns filename as-is if no date prefix" do
      result = filter.documents_title_from_filename("Board_Meeting")
      expect(result).to eq("Board Meeting")
    end

    it "converts underscores to spaces" do
      result = filter.documents_title_from_filename("Some_File_Name")
      expect(result).to eq("Some File Name")
    end
  end
end
