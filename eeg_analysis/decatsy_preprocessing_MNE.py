# Script written by Mehdi Senoussi
# Date: 15.07.19

import numpy as np
import pandas as pd
import matplotlib.pyplot as pl
from scipy import signal as sig
import glob, mne


def rmbase(x, times, poly_order = 1):
	if poly_order > 0:
		p = np.poly1d(np.polyfit(times, x.T, poly_order))
		x2 = x - p(times)
	else:
		x2 = x - x.mean()
	return x2

def cut_weird_amplitudes_raw(x, mask):
	val_to_replace = np.mean(x[[np.where(np.logical_not(mask))[0][0], np.where(np.logical_not(mask))[0][-1]]])
	# threshold = x[mask].min(), x[mask].max()
	x2 = np.zeros(len(mask)) + val_to_replace.mean()
	x2[mask] = x[mask]

	# bad_vals = x[np.logical_not(mask)]
	# bad_vals[(bad_vals>threshold[1])] = threshold[1]
	# bad_vals[(bad_vals<threshold[0])] = threshold[0]
	# x2[np.logical_not(mask)] = bad_vals
	return x2



obs_all = np.array([	   1,	  3,     4,     5,     6,     8,     9,		10,    11,    12,    13,    14, 	15,		16,		17, 	19])
obs_group_all = np.array([ 4,     1,     3,     4,     2,     3,     1,	 	 2,     2,     1,     3,	 4, 	 4, 	 1, 	 2, 	 3])
sesstype_all = np.array([['SBA', 'FBA', 'SBA', 'SBA', 'FBA', 'SBA', 'FBA',	'FBA', 'FBA', 'FBA', 'SBA', 'SBA',  'SBA', 	'FBA', 	'FBA',  'SBA'],
						[ 'FBA', 'SBA', 'FBA', 'FBA', 'SBA', 'FBA', 'SBA',	'SBA', 'SBA', 'SBA', 'FBA', 'FBA',  'FBA', 	'SBA', 	'SBA',  'FBA']])


data_path = '/Volumes/mehdimac/lpp/decatsy/decatsy/decatsy_data/'
base_path = '/Users/mehdi/Dropbox/postphd/lpp/decatsy/'

timep = np.linspace(-.600, 4.474, 1300)
n_timep = len(timep)
epoch_len = timep[-1]-timep[0]

filt = ''

n_elec_tot = 63
n_elec = 60
non_elecs = np.array([4, 20, 9])


# loads the channel file
montage = mne.channels.read_custom_montage(base_path + 'code/elecs/63ElecsDescartes_AFelecs.loc')

do_polyfit_baseline = False
if do_polyfit_baseline:
	poly_order = 50
else:
	poly_order = 0

# observer number
for sess_i in [1, 2]:
	for obs_i in obs_all:
		obs_path = data_path + 'subj%i/' % obs_i
		print('\n\n\n\t\t\t\tobs %i' % obs_i)

		#############################				LOADING DATA			######################################
		# loads all the EEG data files
		raws = []
		# for sess_i in np.arange(1, 3):
		sess_files = glob.glob(obs_path + 'eeg_files/sess%i/*.vhdr' % sess_i)
		blocks = [sess_file_i.split('/')[-1].split('part')[-1].split('.vhdr')[0].split('-')[-1]  for sess_file_i in sess_files]
		file_order = np.argsort(np.array(blocks).astype(np.int))
		for file_i in file_order:
			file_name = sess_files[file_i]
			print('\tfile %s' % file_name)
			block_temp = mne.io.read_raw_brainvision(file_name, eog = ('leftHEOG', 'rightHEOG'), misc = ['M1'], preload = True, verbose = 50)
			elec_switch_dict = dict(zip(block_temp.ch_names, montage.ch_names))
			block_temp.rename_channels(elec_switch_dict)
			block_temp.set_montage(montage)

			if (obs_i==1) & (sess_i==1) & (int(blocks[file_i])==9):
				# take a random electrode's data
				times_bad = np.ones(len(block_temp.times), dtype=np.bool)
				times_bad[109780:112630] = False
				cut_weird_args = {'mask':times_bad}
				block_temp = block_temp.apply_function(cut_weird_amplitudes_raw, channel_wise = True, n_jobs=-1, **cut_weird_args)

			block_temp.load_data()
			if do_polyfit_baseline:
				rmbase_args = {'times':block_temp.times, 'poly_order':poly_order}
				block_temp.apply_function(rmbase, channel_wise = True, n_jobs=6, **rmbase_args)
			block_temp = block_temp.resample(200)

			raws.append(block_temp)

		raw_all = mne.concatenate_raws(raws)

		# apply a average reference
		raw_all = raw_all.set_eeg_reference('average')

		###########################################################
		######		filtering 	###########
		###########################################################

		# store events from the RAW dataset
		events_all, events_all_id = mne.events_from_annotations(raw_all, verbose=50)
		events_all = events_all[(events_all[:, -1]>5) & (events_all[:, -1]<100), :]

		n_evs = len(events_all)
		trial_num = np.zeros(n_evs, dtype = np.int)
		t_num = -1
		for ind, ev in enumerate(events_all):
			t_num += int(ev[-1] == 10)
			trial_num[ind] = t_num

		behav_data_path = obs_path + 'log_files/sess%i/eeg/' % sess_i
		# get all files, each representing a block, in the behav data directory
		all_log = glob.glob(behav_data_path + '*.txt')
		# crearte a pandas dataframe to store all results
		log_allblocks = pd.DataFrame()
		# loop over the log files
		for ind, file_n in enumerate(all_log):
			log_allblocks = log_allblocks.append(pd.read_csv(file_n, delimiter='\t'))

		# put all respTimes of fixBreak and notResponded to -1
		log_allblocks.loc[log_allblocks.respTime == 'fixBreak'] = -1
		log_allblocks.loc[log_allblocks.respTime == 'notResponded'] = -1
		behav_trial_tokeep = np.where(log_allblocks.respTime!=-1)[0]

		# reject the EEG trials which were fixBreaks or notResponded in log trials
		inds_to_keep = np.zeros(n_evs, dtype = np.bool)
		for uni_trnum in np.unique(trial_num):
			mask_un_trnum = trial_num == uni_trnum
			inds_to_keep[mask_un_trnum] = uni_trnum in behav_trial_tokeep

		events_all_clean = events_all[inds_to_keep, :]


		log_allblocks_clean = log_allblocks.loc[log_allblocks.respTime!=-1]

		if sum(events_all_clean[:, -1] == 10) != len(behav_trial_tokeep):
			print('\n\n\n\n\n\n\n\t\t\t\t!!!!!!! PROBLEM NOT SAME NUMBER OF TRIALS IN EEG DATA AND KEEP_TRIAL_EEG !!!!!!!\n\n\n\n\n\n\n')


		raw_all.save(obs_path + 'eeg_files/subj%i_sess%i_raw_data_no_polyfit_lowpass45Hz_raw.fif.gz' % (obs_i, sess_i), overwrite=True)
		np.save(obs_path + 'eeg_files/subj%i_sess%i_events_all_noFixBreak_noNotResponded.npy' % (obs_i, sess_i), events_all_clean)
		log_allblocks_clean.to_csv(obs_path + 'log_files/subj%i_sess%i_log_all_noFixBreak_noNotResponded.csv' % (obs_i, sess_i))






