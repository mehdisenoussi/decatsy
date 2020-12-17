

# Script written by Mehdi Senoussi
# Date: 15.07.19

import numpy as np
import pandas as pd
import mne, os


obs_all = np.array([	   1,	  3,     4,     5,     6,     8,     9,		10,    11,    12,    13,    14, 	15,		16,		17, 	19])
obs_group_all = np.array([ 4,     1,     3,     4,     2,     3,     1,	 	 2,     2,     1,     3,	 4, 	 4, 	 1, 	 2, 	 3])
sesstype_all = np.array([['SBA', 'FBA', 'SBA', 'SBA', 'FBA', 'SBA', 'FBA',	'FBA', 'FBA', 'FBA', 'SBA', 'SBA',  'SBA', 	'FBA', 	'FBA',  'SBA'],
						[ 'FBA', 'SBA', 'FBA', 'FBA', 'SBA', 'FBA', 'SBA',	'SBA', 'SBA', 'SBA', 'FBA', 'FBA',  'FBA', 	'SBA', 	'SBA',  'FBA']])


data_path = '/Volumes/mehdimac/lpp/decatsy/decatsy/decatsy_data/'
base_path = '/Users/mehdi/Dropbox/postphd/lpp/decatsy/'

for obs_i in obs_all:
	if  obs_i>0:
		for sess_i in [1, 2]:
			# make the observer's path
			obs_path = data_path + 'subj%i/' % obs_i
			print('\n\tobs %i' % obs_i)

			# load raw EEG concatenated data
			raw_all = mne.io.read_raw_fif(obs_path + 'eeg_files/subj%i_sess%i_raw_data_no_polyfit_no_filt_raw.fif.gz'\
				% (obs_i, sess_i), verbose = 50, preload=True)
			# raw_all.load_data()
			# load EEG events (i.e. triggers)
			events_all_clean = np.load(obs_path + 'eeg_files/subj%i_sess%i_events_all_noFixBreak_noNotResponded.npy'\
				% (obs_i, sess_i), allow_pickle = True)
			# load log data
			log_allblocks_clean = pd.read_csv(obs_path + 'log_files/subj%i_sess%i_log_all_noFixBreak_noNotResponded.csv'\
				% (obs_i, sess_i))

			# now apply a band-pass filter
			raw_all_filt = raw_all.notch_filter(freqs = 50, trans_bandwidth=4.0, fir_design = 'firwin', verbose = 50)
			# take out electrode M1
			raw_all_filt.drop_channels(['M1'])

			########################################################
			#############   EPOCHING   ###########
			########################################################
			# some observers have faulty EOG electrodes so using a threshold on them removes most trials
			epochs = mne.Epochs(raw_all_filt, events_all_clean, event_id = {'cue':20},
				tmin = -.6, tmax = 3.1, proj = False, baseline = (-.2, -.01), reject = {},
				detrend = None, verbose = 50)
			epochs.metadata = log_allblocks_clean
			epochs.load_data()
			# if cleaning has already been done on this observers, a file with this name should exist
			dropped_eeg_trials_file = obs_path + 'eeg_files/subj%i_sess%i_eeg_cleaning_info.npz' % (obs_i, sess_i)

			if os.path.exists(dropped_eeg_trials_file):
				# if a cleaning info file exists, load it and clean the epochs with its infos
				print('\t\tcleaning info exists for obs %i sess %i' % (obs_i, sess_i))
				eeg_cleaning_infos = np.load(dropped_eeg_trials_file, allow_pickle = True)['arr_0'][..., np.newaxis][0]
				dropped_eeg_trials = eeg_cleaning_infos['dropped_eeg_trials']
				epochs.drop(dropped_eeg_trials)
				epochs.drop_bad()

				bad_channels = eeg_cleaning_infos['bad_channels']
				epochs.info['bads'] = bad_channels
				# if the length of bad_channels is not 0
				if len(bad_channels):
					epochs = epochs.interpolate_bads(reset_bads=True)
			else:
				# if the file doesn't exist, launch the cleaning-by-hand window and then save all info
				epochs.plot(n_epochs = 4, n_channels = 64, scalings = dict(eeg=20e-5),
					events = events_all_clean, block = True)
				bad_channels = epochs.info['bads']

				epochs = epochs.interpolate_bads(reset_bads=True)
				
				# extract the dropped trials
				ev_of_interest = np.where(events_all_clean[:, -1] == 20)[0]
				dropped_eeg_trials = np.zeros(len(ev_of_interest), dtype=np.bool)
				for ind, i in enumerate(ev_of_interest):
					dropped_eeg_trials[ind] = len(epochs.drop_log[i]) != 0
				# save the cleaning info
				np.savez(obs_path + 'eeg_files/subj%i_sess%i_eeg_cleaning_info.npz' % (obs_i, sess_i),
					{'dropped_eeg_trials':dropped_eeg_trials, 'events_all_clean':events_all_clean,
					'bad_channels':bad_channels})
				
			# only keep EEG channels (remove EOGs etc. if there are some left)
			epochs.pick_types(eeg = True)
			epochs.drop_bad()
			# save the epochs
			epochs.save(obs_path + 'eeg_files/subj%i_sess%i_no_polyfit_allclean_-.6_3.1s_baseline_-.2_-.01s_data_Notch_filt-None-NoneHz_epo.fif.gz' % (obs_i, sess_i), overwrite = True)
			# delete all variables to free up memory for next subject
			del raw_all, raw_all_filt, epochs, dropped_eeg_trials, bad_channels
































