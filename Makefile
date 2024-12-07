RELEASE:=bookworm
TARGET:=$(notdir ${CURDIR})

vpath Makefile ..

default: preseed.cfg

main_txt:=debian-preseed-${RELEASE}-amd64-main-full.txt
${main_txt}: Makefile
	curl -Lo $@ https://preseed.debian.net/debian-preseed/${RELEASE}/amd64-main-full.txt

main_cfg:=tmp-$(subst .txt,.cfg,$(main_txt))
${main_cfg}: ${main_txt} Makefile
	sed -n -e '/^# d-i/{s/^# //;s/ <[^ ]*>$$//;p}' $< | LC_ALL=C sort > $@

tmp-current.cfg: Makefile
	ssh ${TARGET} sudo debconf-get-selections --installer > $@
tmp-transform.cfg: tmp-current.cfg Makefile
	awk 'NR==1{print} !/^#/{$$1="d-i"; print}' < $< | LC_ALL=C sort > $@

preseed.cfg: tmp-transform.cfg ${main_cfg} Makefile
	sed -n 1p ${main_txt} > $@
	echo 'd-i passwd/root-password password $${ROOT_PASSWORD}\nd-i passwd/root-password-again password $${ROOT_PASSWORD}' >> $@
	echo 'd-i passwd/user-password password $${USER_PASSWORD}\nd-i passwd/user-password-again password $${USER_PASSWORD}' >> $@
	diff ${main_cfg} $< | sed -n '/^> /{s///;p}' >> $@

.PHONY: clean distclean
clean:
	rm -f ${main_txt} ${main_cfg} tmp-current.cfg tmp-transform.cfg
distclean: clean
	rm -f preseed.cfg
