require "rails_helper"

RSpec.describe Project do
  let!(:project) { create(:project) }

  describe "validations" do
    it {
      is_expected.to validate_inclusion_of(:kind).
        in_array(["standard", "maintenance", "maintenance_incident", "maintenance_release"])
    }
    it { is_expected.to validate_length_of(:name).is_at_most(200) }
    it { is_expected.to validate_length_of(:title).is_at_most(250) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { should_not allow_value("_foo").for(:name) }
    it { should_not allow_value("foo::bar").for(:name) }
    it { should_not allow_value("ends_with_:").for(:name) }
    it { should allow_value("fOO:+-").for(:name) }
  end

  describe "#update_repositories" do
    let!(:repository_1) { create(:repository, name: 'repo_1', rebuild: "direct", project: project) }
    let!(:repository_2) { create(:repository, name: 'repo_2', project: project) }
    let!(:repository_3) { create(:repository, name: 'repo_3', project: project) }

    context "updating repository elements" do
      before do
        xml_hash = Xmlhash.parse(
          <<-EOF
            <project name="#{project.name}">
              <repository name="repo_1" />
              <repository name="new_repo" rebuild="local" block="never" linkedbuild="all" />
            </project>
          EOF
        )
        project.update_repositories(xml_hash, force = false)
      end

      it "updates repositories association of a project" do
        expect(project.repositories.count).to eq 2
        expect(project.repositories.where(name: "repo_1")).to exist
        expect(project.repositories.where(name: "new_repo")).to exist
      end

      it "updates repository attributes of existing repositories" do
        expect(repository_1.reload.rebuild).to be nil
        expect(repository_1.block).to be nil
        expect(repository_1.linkedbuild).to be nil
      end

      it "imports repository attributes of newly created repositories" do
        new_repo = project.repositories.find_by(name: "new_repo")
        expect(new_repo.rebuild).to eq "local"
        expect(new_repo.block).to eq "never"
        expect(new_repo.linkedbuild).to eq "all"
      end
    end
  end
end
