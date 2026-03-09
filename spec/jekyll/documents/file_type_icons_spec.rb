# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jekyll::Documents::FileTypeIcons do
  let(:filter_class) do
    Class.new do
      include Jekyll::Documents::FileTypeIcons
    end
  end
  let(:filter) { filter_class.new }
  let(:context) { double("context", registers: { site: site }) }
  let(:site) { double("site", config: site_config) }
  let(:site_config) { { "documents" => documents_config } }
  let(:documents_config) { { "icon_set" => "color" } }

  describe "#file_type_icon" do
    context "with default icon set" do
      it "returns PDF icon path for pdf" do
        result = filter.file_type_icon("pdf")
        expect(result).to eq("/assets/icons/color/pdf-document-svgrepo-com.svg")
      end

      it "returns DOCX icon path for docx" do
        result = filter.file_type_icon("docx")
        expect(result).to eq("/assets/icons/color/word-document-svgrepo-com.svg")
      end

      it "returns PPTX icon path for pptx" do
        result = filter.file_type_icon("pptx")
        expect(result).to eq("/assets/icons/color/ppt-document-svgrepo-com.svg")
      end

      it "returns XLSX icon path for xlsx" do
        result = filter.file_type_icon("xlsx")
        expect(result).to eq("/assets/icons/color/excel-document-svgrepo-com.svg")
      end

      it "returns default icon for unknown file type" do
        result = filter.file_type_icon("unknown")
        expect(result).to eq("/assets/icons/color/unknown-document-svgrepo-com.svg")
      end

      it "handles case insensitivity" do
        result = filter.file_type_icon("PDF")
        expect(result).to eq("/assets/icons/color/pdf-document-svgrepo-com.svg")
      end

      it "returns same icon for doc and docx" do
        doc_icon = filter.file_type_icon("doc")
        docx_icon = filter.file_type_icon("docx")
        expect(doc_icon).to eq(docx_icon)
      end

      it "returns ODT icon (same as doc)" do
        result = filter.file_type_icon("odt")
        expect(result).to eq("/assets/icons/color/word-document-svgrepo-com.svg")
      end
    end

    context "with lines icon set" do
      let(:documents_config) { { "icon_set" => "lines" } }

      it "returns lines icon path" do
        result = filter.file_type_icon("pdf", context)
        expect(result).to eq("/assets/icons/lines/pdf-svgrepo-com.svg")
      end
    end

    context "with minimal icon set" do
      let(:documents_config) { { "icon_set" => "minimal" } }

      it "returns minimal icon path" do
        result = filter.file_type_icon("pdf", context)
        expect(result).to eq("/assets/icons/minimal/pdf-svgrepo-com.svg")
      end
    end

    context "with ultra-minimal icon set" do
      let(:documents_config) { { "icon_set" => "ultra-minimal" } }

      it "returns ultra-minimal icon path" do
        result = filter.file_type_icon("pdf", context)
        expect(result).to eq("/assets/icons/ultra-minimal/pdf.svg")
      end
    end

    context "with invalid icon set" do
      let(:documents_config) { { "icon_set" => "invalid" } }

      it "falls back to color icon set" do
        result = filter.file_type_icon("pdf", context)
        expect(result).to eq("/assets/icons/color/pdf-document-svgrepo-com.svg")
      end
    end

    context "without context" do
      it "uses default color icon set" do
        result = filter.file_type_icon("pdf")
        expect(result).to eq("/assets/icons/color/pdf-document-svgrepo-com.svg")
      end
    end
  end

  describe "#file_type_icon_tag" do
    it "returns an img tag with correct attributes" do
      result = filter.file_type_icon_tag("pdf")
      expect(result).to include("<img")
      expect(result).to include("src=")
      expect(result).to include("alt=")
      expect(result).to include("class=")
    end

    it "uses default CSS class" do
      result = filter.file_type_icon_tag("pdf")
      expect(result).to include('class="file-icon"')
    end

    it "allows custom CSS class" do
      result = filter.file_type_icon_tag("pdf", css_class: "custom-class")
      expect(result).to include('class="custom-class"')
    end

    it "generates default alt text" do
      result = filter.file_type_icon_tag("pdf")
      expect(result).to include('alt="PDF file"')
    end

    it "allows custom alt text" do
      result = filter.file_type_icon_tag("pdf", alt: "Custom alt")
      expect(result).to include('alt="Custom alt"')
    end

    it "includes correct icon path" do
      result = filter.file_type_icon_tag("pdf")
      expect(result).to include("/assets/icons/color/pdf-document-svgrepo-com.svg")
    end

    it "passes context to file_type_icon" do
      allow(filter).to receive(:file_type_icon).with("pdf", context).and_return("/test/icon.svg")
      result = filter.file_type_icon_tag("pdf", context: context)
      expect(result).to include("/test/icon.svg")
    end
  end
end
