module Admin
  class Ability
    include CanCan::Ability

    def initialize(user)
      return unless user.admin?

      can :read, Order
      can :read, Trade
      can :read, Proof
      can :update, Proof
      can :manage, Document
      can :manage, Member
      can :manage, Ticket
      can :manage, IdDocument
      can :manage, TwoFactor

      can :menu, Deposit
      can :manage, ::Deposits::Satoshi
      can :manage, ::Deposits::Ether
      can :manage, ::Deposits::Travelcoin

      can :menu, Withdraw
      can :manage, ::Withdraws::Satoshi
      can :manage, ::Withdraws::Ether
      can :manage, ::Withdraws::Travelcoin

    end
  end
end
