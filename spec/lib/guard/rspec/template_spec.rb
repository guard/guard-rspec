require "guard/compat/test/template"

# Do not require to simulate Guardfile loading more accurately
# require 'guard/rspec'

RSpec.describe "Guard::RSpec" do
  describe "template" do
    subject { Guard::Compat::Test::Template.new("Guard::RSpec") }

    it "matches spec files by default" do
      expect(subject.changed("spec/lib/foo_spec.rb")).
        to eq(%w(spec/lib/foo_spec.rb))

      expect(subject.changed("spec/spec_helper.rb")).to eq(%w(spec))
    end

    it "matches Ruby files by default" do
      expect(subject.changed("lib/foo.rb")).to eq(%w(spec/lib/foo_spec.rb))
    end

    it "matches Rails files by default" do
      expect(subject.changed("spec/rails_helper.rb")).to eq(%w(spec))

      expect(subject.changed("app/models/foo.rb")).
        to eq(%w(spec/models/foo_spec.rb))

      expect(subject.changed("app/views/foo/bar.slim")).to eq(
        %w(
          spec/views/foo/bar.slim_spec.rb
          spec/features/foo_spec.rb
        )
      )

      expect(subject.changed("app/controllers/application_controller.rb")).
        to eq(
        %w(
          spec/controllers/application_controller_spec.rb
          spec/routing/application_routing_spec.rb
          spec/acceptance/application_spec.rb
          spec/controllers
        )
      )

      expect(subject.changed("app/controllers/foo_controller.rb")).
        to match_array(
        %w(
          spec/controllers/foo_controller_spec.rb
          spec/routing/foo_routing_spec.rb
          spec/acceptance/foo_spec.rb
        )
      )

      expect(subject.changed("config/routes.rb")).to eq(%w(spec/routing))
    end
  end
end
