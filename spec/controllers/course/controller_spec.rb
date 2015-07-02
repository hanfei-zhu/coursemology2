require 'rails_helper'

RSpec.describe Course::Controller, type: :controller do
  controller(Course::Controller) do
    def show
      render text: ''
    end

    def publicly_accessible?
      true
    end
  end

  let(:instance) { create(:instance) }
  with_tenant(:instance) do
    let(:course) { create(:open_course) }
    describe '#current_course' do
      it 'returns the current course' do
        get(:show, id: course.id)
        expect(controller.current_course).to eq(course)
      end
    end

    describe '#current_course_user' do
      context 'when there is no user logged in' do
        it 'returns nil' do
          get(:show, id: course.id)
          expect(controller.current_course_user).to be_nil
        end
      end

      context 'when the user is logged in' do
        let(:user) { create(:administrator) }
        before { sign_in(user) }

        context 'when the user is not registered in the course' do
          it 'returns nil' do
            get(:show, id: course.id)
            expect(controller.current_course_user).to be_nil
          end
        end

        context 'when the user is registered in the course' do
          let!(:course_user) { create(:course_user, course: course, user: user) }
          it 'returns the correct user' do
            get(:show, id: course.id)
            expect(controller.current_course_user.user).to eq(user)
            expect(controller.current_course_user.course).to eq(controller.current_course)
          end
        end
      end
    end

    describe '#current_component_host' do
      it 'returns the component host of current course' do
        allow(controller).to receive(:current_course).and_return(course)
        expect(controller.current_component_host).to be_a Course::ComponentHost
      end
    end

    describe '#all_sidebar_items' do
      it 'returns an empty array when no components included' do
        allow(controller).to receive_message_chain('current_component_host.components').
          and_return([])
        expect(controller.all_sidebar_items).to eq([])
      end
    end

    describe '#ordered_sidebar_items' do
      it 'orders the sidebar items by ascending weight' do
        allow(controller).to receive(:current_course).and_return(course)
        weights = controller.ordered_sidebar_items.map { |item| item[:weight] }
        expect(weights.length).not_to eq(0)
        expect(weights.each_cons(2).all? { |a, b| a <= b }).to be_truthy
      end
    end

    describe '#settings' do
      it 'returns an empty array when no components included' do
        allow(controller).to receive_message_chain('current_component_host.components').
          and_return([])
        expect(controller.settings).to eq([])
      end
    end

    it 'orders the settings items by ascending weight' do
      allow(controller).to receive(:current_course).and_return(course)
      weights = controller.settings.map { |item| item[:weight] }
      expect(weights.length).not_to eq(0)
      expect(weights.each_cons(2).all? { |a, b| a <= b }).to be_truthy
    end
  end
end
