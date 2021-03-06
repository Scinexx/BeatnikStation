//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

/obj/machinery/field/containment
	name = "Containment Field"
	desc = "An energy field."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "Contain_F"
	anchored = 1
	density = 0
	unacidable = 1
	use_power = 0
	luminosity = 4
	layer = OBJ_LAYER + 0.1
	var/obj/machinery/field/generator/FG1 = null
	var/obj/machinery/field/generator/FG2 = null

/obj/machinery/field/containment/Destroy()
	if(FG1 && !FG1.clean_up)
		FG1.cleanup()
	if(FG2 && !FG2.clean_up)
		FG2.cleanup()
	return ..()

/obj/machinery/field/containment/attack_hand(mob/user)
	if(get_dist(src, user) > 1)
		return 0
	else
		shock(user)
		return 1


/obj/machinery/field/containment/blob_act()
	return 0


/obj/machinery/field/containment/ex_act(severity, target)
	return 0


/obj/machinery/field/containment/Crossed(mob/mover)
	if(isliving(mover))
		shock(mover)

/obj/machinery/field/containment/Crossed(obj/mover)
	if(istype(mover, /obj/machinery) || istype(mover, /obj/structure) || istype(mover, /obj/mecha))
		spawn(1) //stops things from bouncing between 2 force fields 9999 times a second creating billions of sparks to lag the server to death. a delay in the bump_field itself only affects mobs for some fucking reason unless there's another delay here
			bump_field(mover)

/obj/machinery/field/containment/proc/set_master(master1,master2)
	if(!master1 || !master2)
		return 0
	FG1 = master1
	FG2 = master2
	return 1

/obj/machinery/field/containment/shock(mob/living/user)
	if(!FG1 || !FG2)
		qdel(src)
		return 0
	..()

/obj/machinery/field/containment/Move()
	qdel(src)

// Abstract Field Class
// Used for overriding certain procs

/obj/machinery/field
	var/hasShocked = 0 //Used to add a delay between shocks. In some cases this used to crash servers by spawning hundreds of sparks every second.

/obj/machinery/field/CanPass(mob/mover, turf/target, height=0)
	if(isliving(mover)) // Don't let mobs through
		shock(mover)
		return 0
	return ..()

/obj/machinery/field/CanPass(obj/mover, turf/target, height=0)
	if((istype(mover, /obj/machinery) && !istype(mover, /obj/singularity)) || \
		istype(mover, /obj/structure) || \
		istype(mover, /obj/mecha))
		spawn(1)
			bump_field(mover)
		return 0
	return ..()

/obj/machinery/field/proc/shock(mob/living/user)
	if(hasShocked)
		return 0
	if(isliving(user))
		hasShocked = 1
		var/shock_damage = min(rand(30,40),rand(30,40))

		if(iscarbon(user))
			var/stun = min(shock_damage, 15)
			user.Stun(stun)
			user.Weaken(10)
			user.burn_skin(shock_damage)
			user.visible_message("<span class='danger'>[user.name] was shocked by the [src.name]!</span>", \
			"<span class='userdanger'>You feel a powerful shock course through your body, sending you flying!</span>", \
			"<span class='italics'>You hear a heavy electrical crack.</span>")

		else if(issilicon(user))
			if(prob(20))
				user.Stun(2)
			user.take_overall_damage(0, shock_damage)
			user.visible_message("<span class='danger'>[user.name] was shocked by the [src.name]!</span>", \
			"<span class='userdanger'>Energy pulse detected, system damaged!</span>", \
			"<span class='italics'>You hear an electrical crack.</span>")

		user.updatehealth()
		bump_field(user)

		spawn(5)
			hasShocked = 0
	return

/obj/machinery/field/proc/bump_field(atom/movable/AM as mob|obj)
	sleep(5) // half a second delay
	if(AM.pulledby) //if someone's pulling, stop them
		AM.pulledby.stop_pulling()
	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	s.set_up(5, 1, AM.loc)
	s.start()
	var/atom/target = get_edge_target_turf(AM, get_dir(src, get_step_away(AM, src)))
	AM.throw_at(target, 200, 4)
	AM.times_bumped_field++
	if(AM.last_bumped_field == -1)
		return
	if(AM.last_bumped_field == 0) //first bump
		AM.last_bumped_field = world.time
	else
		if(world.time - AM.last_bumped_field < 50 && AM.times_bumped_field > 20) //if something bounced more than 20 times and it's been less than 5 seconds since last bounce, alert admins
			var/mob/last = get_mob_by_ckey(AM.fingerprintslast)
			var/turf/T = get_turf(AM)
			var/area/A = get_area(T)
			message_admins("Warning! [AM.name] is bouncing off the containment field too often in <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[AM.x];Y=[AM.y];Z=[AM.z]'>[A.name]</a>, last touched by: [last]! Might be a shitter trying to lag the server. There will be no more alerts for this object. You better check it out, bro!")
			AM.last_bumped_field = -1 //set to -1 to fail the next check and not spam the admins
		else
			AM.last_bumped_field = world.time