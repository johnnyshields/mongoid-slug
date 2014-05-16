#encoding: utf-8
require "spec_helper"

describe "Mongoid::Paranoia with Mongoid::Slug" do

  let(:paranoid_doc)    { ParanoidDocument.create!(:title => "slug") }
  let(:paranoid_doc_2)  { ParanoidDocument.create!(:title => "slug") }
  let(:non_paranoid_doc){ Article.create!(:title => "slug") }

  describe ".paranoid?" do

    context "when Mongoid::Paranoia is included" do
      subject { paranoid_doc.class }
      its(:paranoid?){ should be_true }
    end

    context "when Mongoid::Paranoia not included" do
      subject { non_paranoid_doc.class }
      its(:paranoid?){ should be_false }
    end
  end

  describe "restore callbacks" do

    context "when Mongoid::Paranoia is included" do
      subject { paranoid_doc.class }
      it { should respond_to(:before_restore) }
      it { should respond_to(:after_restore) }
    end

    context "when Mongoid::Paranoia not included" do
      it { should_not respond_to(:before_restore) }
      it { should_not respond_to(:after_restore) }
    end
  end

  describe "indices" do

    pending
    # context "when Mongoid::Paranoia is included" do
    #   subject { paranoid_doc.class }
    #   it { should respond_to(:before_restore) }
    #   it { should respond_to(:after_restore) }
    # end
  end

  context "querying" do

    it "returns paranoid_doc for correct slug" do
      ParanoidDocument.find(paranoid_doc.slug).should eq(paranoid_doc)
    end
  end

  context "deleting (callbacks are not fired)" do

    before { paranoid_doc.delete }

    it "retains slug value" do
      paranoid_doc.slug.should eq "slug"
      ParanoidDocument.unscoped.find("slug").should eq paranoid_doc
    end
  end

  context "destroying" do

    before { paranoid_doc.destroy }

    it "unsets slug value when destroyed" do
      paranoid_doc._slugs.should be_nil
      paranoid_doc.slug.should eq paranoid_doc._id
    end

    it "persists the removed slug" do
      paranoid_doc._slugs.should be_nil
      paranoid_doc.reload.slug.should eq paranoid_doc._id
      ParanoidDocument.unscoped.exists(_slugs: false).first.should eq paranoid_doc
      expect{ParanoidDocument.unscoped.find("slug")}.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end

  context "restoring" do
    before do
      paranoid_doc.destroy
      paranoid_doc = paranoid_doc.reload
      paranoid_doc.restore
    end


    it "resets slug value when restored" do
      paranoid_doc.save
      paranoid_doc.slug.should eq "slug"
      paranoid_doc.reload.slug.should eq "slug"
    end
  end




  context "multiple documents" do

    it "new documents should be able to use the slug of destroyed documents" do
      paranoid_doc.slug.should eq "slug"
      paranoid_doc.destroy
      paranoid_doc.reload.slug.should be_nil
      paranoid_doc_2.slug.should eq "slug"
      paranoid_doc.restore
      paranoid_doc.slug.should eq "slug-1"
      paranoid_doc.reload.slug.should eq "slug-1"
    end

    it "should allow multiple documents to be destroyed without index conflict" do
      paranoid_doc.slug.should eq "slug"
      paranoid_doc.destroy
      paranoid_doc.reload.slug.should be_nil
      paranoid_doc_2.slug.should eq "slug"
      paranoid_doc_2.destroy
      paranoid_doc_2.reload.slug.should be_nil
    end
  end
end
