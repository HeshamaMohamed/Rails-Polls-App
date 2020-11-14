# == Schema Information
#
# Table name: responses
#
#  id               :bigint           not null, primary key
#  respondent_id    :integer          not null
#  answer_choice_id :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Response < ApplicationRecord
  validate :respondent_id, presence: true 
  validate :answer_choice_id, presence: true 
  validate :not_duplicate_response, unless: -> { answer_choice.nil? }
  validate :respondent_is_not_poll_author, unless: -> { answer_choice.nil? }

  belongs_to(
    :answer_choice,
    class_name: 'AnswerChoice',
    foreign_key: :answer_choice_id,
    primary_key: :id
  )

  belongs_to(
    :respondent,
    class_name: 'User',
    foreign_key: :respondent_id,
    primary_key: :id
  )

  has_one :question, 
  through: :answer_choice 
  source: :question
  

  

  def sibling_responses
      self.question.responses.where.not("responses.id = ?", self.id)
  end

  def respondent_already_answered?
      sibling_responses.exists?("responses.respondent_id = ?", self.id)
  end
  
  def not_duplicate_response
    if respondent_already_answered?
      errors[:respondent_id] << 'cannot vote twice for question'
    end
  end
  
  def respondent_is_not_poll_author
    # The 3-query slow way:
    # poll_author_id = self.answer_choice.question.poll.author_id

    # 1-query; joins two extra tables.
    poll_author_id = Poll
      .joins(questions: :answer_choices)
      .where('answer_choices.id = ?', self.answer_choice_id)
      .pluck('polls.author_id')
      .first

    if poll_author_id == self.respondent_id
      errors[:respondent_id] << 'cannot be poll author'
    end
  end


end