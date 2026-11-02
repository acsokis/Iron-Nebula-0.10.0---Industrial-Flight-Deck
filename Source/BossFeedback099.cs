using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace IronNebula;

/// <summary>
/// Alpha 0.9.9: transient HD boss hull fractures, phase telegraphs and audio hooks.
/// These effects are visual only; no collision positions or HP values change.
/// </summary>
public sealed partial class IronNebulaGame
{
    private sealed class BossBreach
    {
        public Vector2 Position;
        public float Age;
        public float Life;
        public float Scale;
        public float Rotation;
        public Color Tint;
    }

    private Texture2D? _bossBreachTexture;
    private readonly List<BossBreach> _bossBreaches=new();

    private void LoadBossFeedback099()
        => _bossBreachTexture=LoadImage("FX/boss_breach_099.png");

    private bool HasActiveBossForMusic()
    {
        if(_mode!=GameMode.Playing) return false;
        foreach(Enemy e in _enemies)
        {
            if(e.Health<=0) continue;
            if(e.Kind==EnemyKind.Warden || e.Kind==EnemyKind.Sentinel ||
               e.Kind==EnemyKind.RiftGuardian || e.Kind==EnemyKind.RiftColossus ||
               e.Kind==EnemyKind.InfernoGuardian || e.Kind==EnemyKind.InfernoTitan)
                return true;
        }
        return false;
    }

    private static bool IsBossOrModule(Enemy e)
        => e.Kind==EnemyKind.Warden || e.Kind==EnemyKind.Sentinel ||
           e.Kind==EnemyKind.RiftGuardian || e.Kind==EnemyKind.RiftColossus ||
           e.Kind==EnemyKind.InfernoGuardian || e.Kind==EnemyKind.InfernoTitan ||
           e.Kind==EnemyKind.RiftBossTurret || e.Kind==EnemyKind.InfernoBossTurret;

    private void AdvanceBossCombatPhase(Enemy enemy,float dt)
    {
        if(!GameplayRules.IsCombatBoss(enemy.Kind)) return;
        enemy.BossPhaseTimer+=dt;
        BossCombatPhase next=GameplayRules.BossCombatPhaseAt(enemy.BossPhaseTimer);
        if(next==enemy.BossPhase) return;
        enemy.BossPhase=next;
        if(next==BossCombatPhase.Attack) enemy.FireTimer=MathF.Max(enemy.FireTimer,.7f);
        _audio?.Effect("boss_phase",.22f,next==BossCombatPhase.Shield?.76f:1.04f);
        Alert(next switch
        {
            BossCombatPhase.Shield=>"BOSS SHIELD PHASE",
            BossCombatPhase.Damage=>"BOSS DAMAGE WINDOW",
            _=>"BOSS ATTACK PHASE"
        },1.2f);
    }

    private void DrawBossCombatShield(Enemy enemy,Vector2 position)
    {
        if(enemy.BossPhase!=BossCombatPhase.Shield||_shieldRing==null) return;
        float pulse=1f+.035f*MathF.Sin(enemy.Age*8f);
        float scale=enemy.Radius*2.35f/Math.Max(1,_shieldRing.Width)*pulse;
        _batch.Draw(_shieldRing,position,null,BossAccent(enemy.Kind)*.70f,0f,
            new Vector2(_shieldRing.Width*.5f,_shieldRing.Height*.5f),scale,
            SpriteEffects.None,0f);
    }

    private static Color BossAccent(EnemyKind kind)
        => kind switch
        {
            EnemyKind.RiftGuardian or EnemyKind.RiftColossus or EnemyKind.RiftBossTurret
                => new Color(205,133,255),
            EnemyKind.InfernoGuardian or EnemyKind.InfernoTitan or EnemyKind.InfernoBossTurret
                => new Color(255,145,59),
            _=>new Color(102,211,255)
        };

    private void AddBossBreach(Vector2 position,Color tint,float scale,float life=.34f)
    {
        if(!_combatFxEnabled || _bossBreachTexture==null) return;
        if(_bossBreaches.Count>=42) _bossBreaches.RemoveAt(0);
        _bossBreaches.Add(new BossBreach
        {
            Position=position,
            Scale=scale,
            Life=life,
            Rotation=FxRand(-.55f,.55f),
            Tint=tint
        });
    }

    // Both repeated Beam ticks and rapid Gatling hits are throttled per enemy.
    private void OnBossImpact(Enemy enemy,Vector2 hitPosition)
    {
        if(!IsBossOrModule(enemy) || !_combatFxEnabled || enemy.Health<=0) return;
        if(enemy.Age-enemy.LastBossImpactAge<.22f) return;
        enemy.LastBossImpactAge=enemy.Age;
        float damage=1f-enemy.Health/(float)Math.Max(1,enemy.MaxHealth);
        Color tint=BossAccent(enemy.Kind);
        AddBossBreach(hitPosition,tint,enemy.Parent!=null?.35f:.52f,.25f);
        if(damage>.48f)
        {
            Vector2 flare=enemy.Position+new Vector2(FxRand(-55f,30f),FxRand(-43f,43f));
            AddBossBreach(flare,tint,.47f,.55f);
        }
    }

    private void OnBossPhaseChanged(Enemy enemy,int phase)
    {
        Color tint=BossAccent(enemy.Kind);
        _audio?.Effect("boss_phase",.28f,.88f);
        if(!_combatFxEnabled) return;
        Vector2 core=enemy.Position+new Vector2(-55f,0f);
        AddBossBreach(core,tint,.90f,.72f);
        AddBossBreach(core+new Vector2(-90f,-72f),tint,.52f,.42f);
        AddBossBreach(core+new Vector2(37f,76f),tint,.56f,.51f);
        SpawnCombatFlash(core,-Vector2.UnitX,tint,125f,.29f);
        if(phase>=3)
            SpawnCombatBurst(core,tint,28,120f,430f);
    }

    private void OnBossModuleDestroyed(Enemy module)
    {
        _audio?.Effect("boss_module",.09f,.85f);
        Color tint=BossAccent(module.Kind);
        AddBossBreach(module.Position,tint,.78f,.46f);
        AddBossBreach(module.Position+new Vector2(-29f,21f),tint,.41f,.32f);
        if(_combatFxEnabled)
            SpawnExplosionSprite(module.Position,.44f,.058f);
    }

    private void OnBossFinale(Vector2 position,bool rift,bool inferno)
    {
        _audio?.Effect("boss_finale",.4f,.96f);
        Color tint=rift?new Color(206,126,255):inferno?new Color(255,139,54):new Color(93,201,255);
        AddBossBreach(position+new Vector2(-115,-66),tint,1.26f,.77f);
        AddBossBreach(position+new Vector2(59,104),tint,.94f,.88f);
        AddBossBreach(position+new Vector2(-29,12),tint,1.68f,1.43f);
    }

    private void UpdateBossBreaches(float dt)
    {
        for(int i=_bossBreaches.Count-1;i>=0;i--)
        {
            BossBreach fx=_bossBreaches[i];
            fx.Age+=dt;
            if(fx.Age>=fx.Life) _bossBreaches.RemoveAt(i);
        }
    }

    // Called during the additive lighting pass, using a transparent irregular fissure sprite.
    private void DrawBossBreaches()
    {
        if(!_combatFxEnabled || _bossBreachTexture==null) return;
        Vector2 origin=new(_bossBreachTexture.Width*.5f,_bossBreachTexture.Height*.5f);
        foreach(BossBreach fx in _bossBreaches)
        {
            float t=MathHelper.Clamp(fx.Age/fx.Life,0f,1f);
            float fade=(1f-t)*(1f-t);
            _batch.Draw(_bossBreachTexture,fx.Position,null,fx.Tint*(.71f*fade),fx.Rotation,
                origin,fx.Scale*(.88f+.17f*t),SpriteEffects.None,0f);
        }
    }

    private void OpenNewGameDifficulty()
    {
        _helpOpen=false;
        _settingsOpen=false;
        _audio?.Beam(false);
        _difficultyPromptOpen=true;
        _audio?.Effect("shop",.05f,.32f);
    }

    private void DrawNewGameDifficultyPrompt()
    {
        Shade();
        Color cyan=new(116,231,255),gold=new(255,198,95);
        DrawCleanPanel(new Rectangle(315,120,1290,837),cyan);
        _ui.TextShadow(_batch,"SELECT DIFFICULTY",new Vector2(ViewWidth/2,190),1.13f,Color.White,true);
        _ui.TextShadow(_batch,"CHOOSE BEFORE LAUNCH",new Vector2(ViewWidth/2,294),.53f,cyan,true);
        string[] titles={"EASY","NORMAL","HARD"};
        string[] details={"78% ENEMY HULL  /  RELAXED FIRE","CLASSIC BALANCED COMBAT","132% ENEMY HULL  /  FASTER FIRE"};
        for(int i=0;i<3;i++)
        {
            bool selected=(int)_selectedDifficulty==i;
            Rectangle r=new(450,400+i*145,1020,129);
            DrawMenuButton(r,titles[i],selected,false,.89f);
            _ui.TextShadow(_batch,details[i],new Vector2(ViewWidth/2,475+i*145),.39f,
                selected?gold:new Color(146,186,210),true);
        }
        _ui.TextShadow(_batch,NavigatePrompt+" CHOOSE    "+ConfirmPrompt+" LAUNCH    "+BackPrompt+" BACK",
            new Vector2(ViewWidth/2,910),.36f,cyan,true);
    }
}
