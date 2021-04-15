function draw(q)

if Topo.istopo(q)
    q = Topo.to(q);
end

%% Animation


% (x, y, theta, q1R, q2R, q1L, q2L)
anim = Animator.FiveLinkAnimator(0, q);
anim.pov = Animator.AnimatorPointOfView.West;
anim.Animate(true);
anim.isLooping = false;
anim.updateWorldPosition = true;
anim.endTime = 1;
end