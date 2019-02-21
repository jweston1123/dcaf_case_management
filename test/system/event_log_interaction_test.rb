require 'application_system_test_case'

class EventLogInteractionTest < ApplicationSystemTestCase
  before do
    @user = create :user, role: 'admin', name: 'Billy'
    @user2 = create :user, role: 'cm', name: 'Susie'

    @patient = create :patient, name: 'tester',
                                primary_phone: '1231231234',
                                created_by: @user,
                                city: 'Washington'
    log_in_as @user
    visit edit_patient_path @patient

  end

  describe 'logging phone calls' do
    it 'should log a phone call into the activity log' do
      wait_for_element 'Call Log'
      click_link 'Call Log'
      click_link 'Record new call'
      assert_modal_visible
      wait_for_element 'I left a voicemail for the patient'
      click_link 'I left a voicemail for the patient'
      wait_for_ajax
      assert_modal_hidden
      log_out && log_in_as(@user2)
      wait_for_css '#activity_log_content'
      wait_for_css '#event-item'
      wait_for_ajax
      wait_for_no_css '.sk-spinner'

      assert_difference '@user2.patients.count', 1 do
        within :css, '#activity_log_content' do
          assert has_content? "#{@user.name} left a voicemail for " \
                              "#{@patient.name}"
        end
        click_link '(Add to call list)'
        wait_for_ajax
        @user2.reload
      end
    end

  end
end

def modal_wrapper_id
  '#123-123-1234'
end

def assert_modal_visible
  expect(page).to have_selector(modal_wrapper_id, visible: true)
rescue Capybara::TimeoutError
  flunk 'Expected modal to be visible.'
end

def assert_modal_closed
  expect(page).to have_selector(modal_wrapper_id, visible: false)
rescue Capybara::TimeoutError
  flunk 'Expected modal to be hidden.'
end

