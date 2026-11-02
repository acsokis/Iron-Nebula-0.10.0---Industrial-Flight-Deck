namespace IronNebula;

internal static class GameplayRules
{
    internal const float BossAttackDuration=4.5f;
    internal const float BossShieldDuration=2f;
    internal const float BossDamageDuration=2.5f;

    internal static BossCombatPhase BossCombatPhaseAt(float elapsed)
    {
        float cycle=BossAttackDuration+BossShieldDuration+BossDamageDuration;
        float position=((elapsed%cycle)+cycle)%cycle;
        return position<BossAttackDuration?BossCombatPhase.Attack:
            position<BossAttackDuration+BossShieldDuration?BossCombatPhase.Shield:
            BossCombatPhase.Damage;
    }

    internal static bool IsCombatBoss(EnemyKind kind)
        =>kind==EnemyKind.Warden || kind==EnemyKind.Sentinel ||
          kind==EnemyKind.RiftGuardian || kind==EnemyKind.RiftColossus ||
          kind==EnemyKind.InfernoGuardian || kind==EnemyKind.InfernoTitan;

    internal static bool IsBossShielded(Enemy enemy)
        =>IsCombatBoss(enemy.Kind)&&enemy.BossPhase==BossCombatPhase.Shield;

    internal static int ResolveBossDamage(Enemy enemy,int damage)
        =>IsCombatBoss(enemy.Kind)&&enemy.BossPhase==BossCombatPhase.Damage
            ?Math.Max(1,(int)MathF.Ceiling(damage*1.5f)):damage;

    internal static float PartyEnemyHealthMultiplier(int partySize)
        =>1f+.08f*(Math.Clamp(partySize,1,6)-1);

    internal static float PartyEnemyFireRateMultiplier(int partySize)
        =>1f+.025f*(Math.Clamp(partySize,1,6)-1);

    internal static float PartyPickupMultiplier(int partySize)
        =>1f+.04f*(Math.Clamp(partySize,1,6)-1);

    internal static int ScalePickupUnits(int units,int partySize)
        =>units+(Math.Clamp(partySize,1,6)-1)/3;
}
